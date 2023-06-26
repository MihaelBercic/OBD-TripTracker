//
//  BluetoothManager.swift
//  CarInfo
//
//  Created by Mihael Bercic on 24/06/2023.
//

import ActivityKit
import CoreBluetooth
import Foundation

class MeasurementsDictionary: ObservableObject {
	@Published var measurements: [UInt8: Measurement] = [:]
	@Published var activity: Activity<CarWidgetAttributes>? = nil
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
	var measurements: MeasurementsDictionary?
	private var manager: CBCentralManager?
	private var adapter: CBPeripheral? = nil
	private var outgoingQueue = Queue<Message>()
	private var processingQueue = DispatchQueue(label: "processingQueue")

	private let advertisedUUID = CBUUID(string: "18F0")
	private let serviceUUID = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")
	private let characteristicUUID = CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")

	func setup(_ measurements: MeasurementsDictionary) {
		self.measurements = measurements
		print("Setup")
		manager = CBCentralManager(delegate: self, queue: nil)
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		if central.state == .poweredOn {
			print("Scanning for peripherals")
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
		print("Successfully connected to \(peripheral.name ?? "UNKNOWN")")
		peripheral.discoverServices([serviceUUID])
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
		peripheral.services?.forEach { service in
			peripheral.discoverCharacteristics([characteristicUUID], for: service)
		}
	}

	func peripheral(_: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
		guard let adapter = adapter else { return }
		service.characteristics?.forEach { characteristic in
			adapter.setNotifyValue(true, for: characteristic)
			// adapter.writeValue(Data("AT Z\r".utf8), for: characteristic, type: .withoutResponse)
			adapter.writeValue(Data("AT E0\r".utf8), for: characteristic, type: .withoutResponse)
			sleep(1)
			adapter.writeValue(Data("AT SP 0\r".utf8), for: characteristic, type: .withoutResponse)
			sleep(1)
			adapter.writeValue(Data("AT L1\r".utf8), for: characteristic, type: .withoutResponse)
			sleep(1)

			let initialMessage = Message(sid: "01", pids: PIDs.engineLoad, PIDs.engineSpeed, PIDs.engineCoolantTemperature)
			outgoingQueue.enqueue(initialMessage)
			adapter.writeValue(Data("\(initialMessage.encodedData)\r".utf8), for: characteristic, type: .withoutResponse)
		}
	}

	func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
		guard let data = characteristic.value else { return }
		guard var enqueuedMessage = outgoingQueue.peek() else { return }

		let encodedData = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: ["\r", "\n", ">"]) ?? "00"

		// print("Response: \(encodedData)")

		if encodedData.contains("NOT FOUND") || encodedData.contains("UNABLE") || encodedData.contains("ERROR") {
			adapter?.writeValue(Data("\(enqueuedMessage.encodedData)\r".utf8), for: characteristic, type: .withoutResponse)
			return
		}

		if !encodedData.contains(":") { return }
		let lines = encodedData.split(separator: "\r\n")
		for line in lines {
			if !line.contains(":") { continue }
			var split = line.trimmingCharacters(in: ["\r", "\n"]).split(separator: ":")[1].trimmingPrefix(" ").split(separator: " ").map { String($0) }
			let isResponseIndicator = split[0] == "41"
			if isResponseIndicator {
				split.removeFirst()
			}
			enqueuedMessage.responseData.append(contentsOf: split)
		}
		if enqueuedMessage.canBeProcessed {
			outgoingQueue.dequeue()
			processingQueue.sync {
				enqueuedMessage.processMessage()

				var trip = Trip()
				enqueuedMessage.responseMeasurements.forEach { (key: UInt8, value: Measurement<Unit>) in
					measurements?.measurements.updateValue(value, forKey: key)
					switch key {
					case PIDs.engineCoolantTemperature.id:
						trip.engineTemp = value.value
					case PIDs.engineSpeed.id:
						trip.currentRpm = value.value
					case _: ()
					}
				}

				if let activity = measurements?.activity {
					let newState = CarWidgetAttributes.ContentState(trip: trip)
					Task {
						await activity.update(using: newState)
					}
				}

				let newMessage = Message(sid: enqueuedMessage.sid, pids: enqueuedMessage.pids)
				outgoingQueue.enqueue(newMessage)
				usleep(300_000)
				adapter?.writeValue(Data("\(newMessage.encodedData)\r".utf8), for: characteristic, type: .withoutResponse)
				measurements?.measurements.forEach { (key: UInt8, value: Measurement<Unit>) in
					print("\(key) == \(value)")
				}
			}
		}
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: Error?) {
		central.connect(peripheral)
	}
}

public extension UInt8 {
	var asBinary: String {
		let binaryRepresentation = String(self, radix: 2)
		let requiredZeros = 8 - binaryRepresentation.count
		return repeatElement("0", count: requiredZeros) + binaryRepresentation
	}
}
