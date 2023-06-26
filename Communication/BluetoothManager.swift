//
//  BluetoothManager.swift
//  CarInfo
//
//  Created by Mihael Bercic on 24/06/2023.
//

import ActivityKit
import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

	private var messageInterval = 0.3

	private let advertisedUUID = CBUUID(string: "18F0")
	private let serviceUUID = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")
	private let characteristicUUID = CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")

	private var manager: CBCentralManager? = nil
	private var adapter: CBPeripheral? = nil

	private var messageQueue = Queue<Message>()
	private var outgoingQueue = DispatchQueue(label: "outgoingQueue")
	private var processingQueue = DispatchQueue(label: "processingQueue")

	private let trimmingCharacterSet: CharacterSet = ["\r", "\n", ">"]

	override init() {
		super.init()
		manager = CBCentralManager(delegate: self, queue: nil)
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		if central.state == .poweredOn {
			central.scanForPeripherals(withServices: [advertisedUUID])
		}
	}

	func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
		if peripheral.name != "IOS-Vlink" {
			return
		}

		peripheral.delegate = self
		manager?.use {
			$0.connect(peripheral)
			$0.stopScan()
		}
		adapter = peripheral
	}

	func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
		peripheral.discoverServices([serviceUUID])
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
		peripheral.services?.forEach {
			peripheral.discoverCharacteristics([characteristicUUID], for: $0)
		}
	}

	func peripheral(_: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
		guard let adapter = adapter else { return }
		service.characteristics?.forEach { characteristic in
			adapter.setNotifyValue(true, for: characteristic)
			// adapter.writeValue(Data("AT Z\r".utf8), for: characteristic, type: .withoutResponse)
			sendToAdapter("AT E0", characteristic)
			sendToAdapter("AT SP 0", characteristic)
			sendToAdapter("AT L1", characteristic)

			let initialMessage = Message(characteristic, sid: "01", pids: PIDs.engineLoad, PIDs.engineSpeed, PIDs.engineCoolantTemperature)
			sendToAdapter(initialMessage)
		}
	}

	func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
		guard let data = characteristic.value else { return }
		guard var currentMessage = messageQueue.peek() else { return }

		let encodedData = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: trimmingCharacterSet) ?? "00"
		// print("Response: \(encodedData)")

		if encodedData.contains("NOT|UNABLE|ERROR") {
			messageInterval = 1
			sendToAdapter(currentMessage)
			return
		}

		messageInterval = 0.3

		let matches = encodedData.matches(of: /.*: (.*)/)
			.flatMap { $0.1.split(separator: " ") }
			.dropFirst()
			.map { String($0) }

		currentMessage.responseData.append(contentsOf: matches)
		if currentMessage.canBeProcessed {
			guard var enqueuedMessage = messageQueue.dequeue() else { return }
			processingQueue.sync {
				enqueuedMessage.processMessage()
				enqueuedMessage.responseMeasurements.forEach { (_: UInt8, _: Measurement<Unit>) in
				}
				enqueuedMessage.reset()
				sendToAdapter(enqueuedMessage)
			}
		}
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: Error?) {
		central.connect(peripheral)
	}

	private func sendToAdapter(_ message: Message) {
		guard let characteristic = message.characteristic else { return }
		if !messageQueue.contains(message) {
			messageQueue.enqueue(message)
		}
		sendToAdapter(message.encodedRequest, characteristic)
	}

	private func sendToAdapter(_ message: String, _ characteristic: CBCharacteristic) {
		guard let adapter = adapter else { return }
		let data = Data(message.appending("\r").utf8)
		outgoingQueue.sync {
			adapter.writeValue(data, for: characteristic, type: .withoutResponse)
			Thread.sleep(forTimeInterval: messageInterval)
		}
	}
}

public extension UInt8 {
	var asBinary: String {
		let binaryRepresentation = String(self, radix: 2)
		let requiredZeros = 8 - binaryRepresentation.count
		return repeatElement("0", count: requiredZeros) + binaryRepresentation
	}
}
