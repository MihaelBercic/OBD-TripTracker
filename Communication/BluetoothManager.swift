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

	private var interestedIn: [PIDs] = []
	private var messageInterval = 1.0

	private let advertisedUUID = CBUUID(string: "18F0")
	private let serviceUUID = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")
	private let characteristicUUID = CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")
	private let trimmingCharacterSet: CharacterSet = [" ", "\r", "\n", ">"]

	private var manager: CBCentralManager? = nil
	private var adapter: CBPeripheral? = nil
	private var characteristic: CBCharacteristic? = nil

	private let requestQueue = Queue<Request>()
	private let outgoingMessageQueue = Queue<String>()
	private let measurementProcessingQUeue = Queue<MeasuredValue>()
	private var responseManager: ResponseManager? = nil

	init(interestedIn: [PIDs] = []) {
		super.init()
		self.interestedIn.append(contentsOf: interestedIn)
		manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "central-manager-identifier"])

		responseManager = ResponseManager(measurementQueue: measurementProcessingQUeue)

		Thread(block: processOutgoingQueue).start()
		Thread(block: processRequests).start()
		Thread(block: processMeasurements).start()
		print("Bluetooth manager initialised...")
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		print("Updated CBManager state to \(central.state) vs \(CBManagerState.poweredOn)")
		if central.state == .poweredOn {
			let connected = central.retrieveConnectedPeripherals(withServices: [advertisedUUID])
			guard let adapter = connected.first(where: { $0.name == "IOS-Vlink" }) else {
				central.scanForPeripherals(withServices: [advertisedUUID])
				return
			}
			self.adapter = adapter
			adapter.delegate = self
			adapter.discoverServices([serviceUUID])
			print("Trying to connect to our adapter!")
		}
	}

	func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
		if peripheral.name != "IOS-Vlink" {
			return
		}
		print("Discovered our adapter!")
		guard let manager = manager else { return }
		peripheral.delegate = self
		adapter = peripheral
		manager.connect(peripheral)
		manager.stopScan()
	}

	func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("Connected to our adapter!")
		adapter = peripheral
		peripheral.discoverServices([serviceUUID])
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
		guard let importantService = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else { return }
		print("Discovered the important service!")
		peripheral.discoverCharacteristics([characteristicUUID], for: importantService)
	}

	func peripheral(_: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
		guard let adapter = adapter else { return }
		guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else { return }
		print("Discovered the important characteristic!")
		self.characteristic = characteristic

		messageInterval = 2
		adapter.setNotifyValue(true, for: characteristic)
//		sendToAdapter("AT Z")
		sendToAdapter("AT E0")
		sendToAdapter("AT SP 0")
		sendToAdapter("AT L0")
		sendToAdapter("AT H1")

		let pidsChunked = interestedIn.chunked(into: 3)
		let requestsMapped = pidsChunked.map { Request(sid: "01", pids: $0) }

		requestsMapped.forEach { sendToAdapter($0) }
	}

	func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
		guard let data = characteristic.value else { return }
		guard let responseManager = responseManager else { return }
		let encodedData = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: trimmingCharacterSet) ?? "00"

		print("> \(encodedData)")

		guard let currentRequest = requestQueue.peek() else { return }

		if encodedData.contains(/NO|UNABLE|ERROR|STOPPED/) {
			messageInterval = 2
			print("Retrying in 2 seconds...")
			sendToAdapter(currentRequest)
			return
		}

		print(encodedData.split(separator: " ").count < 3)

		if encodedData.split(separator: " ").count < 3 { return }
		messageInterval = 0.3

		let lines = encodedData.split(whereSeparator: \.isNewline)
		lines.filter { !$0.isEmpty && $0.contains(" ") }.forEach {
			responseManager.prepare(message: String($0))
		}

		if responseManager.canSend {
			requestQueue.moveToTheBack()
		}
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: Error?) {
		requestQueue.clear()
		outgoingMessageQueue.clear()
		measurementProcessingQUeue.clear()
		central.connect(peripheral)
		TripSingleton.shared.stopTrip()
		print("Will try to reconnect!")
	}

	func centralManager(_: CBCentralManager, willRestoreState state: [String: Any]) {
		guard let restoredPeripherals = state[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
		guard let ourAdapter = restoredPeripherals.first(where: { $0.name == "IOS-Vlink" }) else { return }
		adapter = ourAdapter
	}

	func sendToAdapter(_ message: String) {
		outgoingMessageQueue.enqueue(message)
	}

	func sendToAdapter(_ request: Request) {
		if !requestQueue.contains(request) {
			requestQueue.enqueue(request)
		} else {
			outgoingMessageQueue.enqueue(request.encodedRequest)
		}
	}

	private func processRequests() {
		while true {
			requestQueue.semaphore.wait()
			guard let nextRequest = requestQueue.peek() else { continue }
			outgoingMessageQueue.enqueue(nextRequest.encodedRequest)
		}
	}

	private func processOutgoingQueue() {
		while true {
			outgoingMessageQueue.semaphore.wait()
			guard let characteristic = characteristic, let adapter = adapter else { continue }
			guard let nextMessage = outgoingMessageQueue.dequeue() else { continue }
			let data = Data("\(nextMessage)\r".utf8)
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + messageInterval) {
				adapter.writeValue(data, for: characteristic, type: .withoutResponse)
				print("\(Date().timeIntervalSince1970)\tSent out a message => \(nextMessage)")
			}
		}
	}

	private func processMeasurements() {
		while true {
			measurementProcessingQUeue.semaphore.wait()
			guard let measuredValue = measurementProcessingQUeue.dequeue() else { continue }
			TripSingleton.shared.updateTrip(measuredValue: measuredValue)
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

extension Array {
	func chunked(into size: Int) -> [[Element]] {
		return stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
}
