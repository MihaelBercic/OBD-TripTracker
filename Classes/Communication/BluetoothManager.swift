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

	private let adapterName = "IOS-Vlink"
	private let advertisedUUID = CBUUID(string: "18F0")
	private let serviceUUID = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")
	private let characteristicUUID = CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")
	private let trimmingCharacterSet: CharacterSet = [" ", "\r", "\n", ">"]

	private var manager: CBCentralManager? = nil
	private var adapter: CBPeripheral? = nil
	private var characteristic: CBCharacteristic? = nil

	private let outgoingSemaphore: DispatchSemaphore = .init(value: 0)
	private var responseManager: ResponseManager = .init()
	private let requestQueue = Queue<Request>()
	private let outgoingMessageQueue = Queue<String>()

	init(interestedIn: [PIDs] = []) {
		super.init()
		self.interestedIn.append(contentsOf: interestedIn)
		manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "central-manager-identifier"])

		Thread(block: processOutgoing).start()
		Thread(block: processRequests).start()
		Logger.shared.info("BM initialised")
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		// print("Updated CBManager state to \(central.state) vs \(CBManagerState.poweredOn) with \(adapter)")
		if central.state == .poweredOn {
			let isConnected = adapter != nil
			if isConnected {
				Logger.shared.info("Adapter is connected, discovering services...")
				adapter?.use {
					if $0.state == .connected { $0.discoverServices([serviceUUID]) }
					else { central.connect($0) }
				}
			} else {
				Logger.shared.info("📡 Scanning for peripherals...")
				central.scanForPeripherals(withServices: [advertisedUUID])
			}
		}
	}

	func centralManager(_ manager: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
		if peripheral.name != "IOS-Vlink" { return }
		manager.stopScan()
		Logger.shared.info("📍 Discovered our adapter!")
		adapter = peripheral.apply {
			$0.delegate = self
			manager.connect($0)
		}
	}

	func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
		Logger.shared.info("✅ Connected to our adapter!")
		adapter = peripheral
		peripheral.discoverServices([serviceUUID])
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
		guard let importantService = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else { return }
		Logger.shared.info("📍 Discovered the important service!")
		peripheral.discoverCharacteristics([characteristicUUID], for: importantService)
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
		guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else { return }
		self.characteristic = characteristic
		Logger.shared.info("📍 Discovered the important characteristic!")

		peripheral.setNotifyValue(true, for: characteristic)
		addToOutgoingQueue("AT E0",
		                   "AT SP 0",
		                   "AT L0",
		                   "AT H1")

		let pidsChunked = interestedIn.chunked(into: 3)
		let requestsMapped = pidsChunked.map { Request(sid: "01", pids: $0) }

		requestsMapped.forEach { requestQueue.enqueue($0) }
	}

	func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
		guard let data = characteristic.value else { return }
		guard let encodedData = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: trimmingCharacterSet) else { return }

		let shouldIgnoreResponse = data.count <= 1 || encodedData.contains(/SEARCHING/)
		print("🔊 \(encodedData)")
		if shouldIgnoreResponse { return }

		defer {
			adapter?.readRSSI()
			outgoingMessageQueue.semaphore.signal()
		}

		if encodedData.contains(/NO|UNABLE|ERROR|STOPPED/) {
			Logger.shared.info("No|Unable|Error|Stopped")
			messageInterval = 5
			requestQueue.moveToTheBack()
		} else {
			if encodedData.split(separator: " ").count < 3 {
				Logger.shared.info("Data is shorter \(encodedData)...")
				return
			}
			messageInterval = 1

			let lines = encodedData.split(whereSeparator: \.isNewline)
			lines.filter { !$0.isEmpty && $0.contains(" ") }.forEach {
				responseManager.prepare(message: String($0))
			}

			if responseManager.canSend {
				requestQueue.moveToTheBack()
			}
		}
	}

	func peripheral(_: CBPeripheral, didReadRSSI rssiValue: NSNumber, error _: Error?) {
		Logger.shared.info("RSSI: \(rssiValue.decimalValue)")
		if rssiValue.decimalValue < -80 {
			messageInterval = 10
		}
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: Error?) {
		central.connect(peripheral)
		TripSingleton.shared.stopTrip()
		Logger.shared.info("Will try to reconnect!")
	}

	func centralManager(_ central: CBCentralManager, willRestoreState state: [String: Any]) {
		Logger.shared.info("Will restore state!")
		guard let restoredPeripherals = state[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
		guard let ourAdapter = restoredPeripherals.first(where: { $0.name == adapterName }) else { return }
		Logger.shared.info("Restoring state and adapter exists!")
		adapter = ourAdapter.apply {
			$0.delegate = self
			central.connect($0)
		}
	}

	private func processRequests() {
		while true {
			requestQueue.semaphore.wait()
			guard let request = requestQueue.peek() else { continue }
			addToOutgoingQueue(request.encodedRequest)
		}
	}

	private func processOutgoing() {
		while true {
			guard let message = outgoingMessageQueue.dequeue() else { continue }
			guard let characteristic = characteristic else { continue }
			guard let adapter = adapter else { continue }
			let data = Data("\(message)\r".utf8)

			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + messageInterval) {
				adapter.writeValue(data, for: characteristic, type: .withoutResponse)
				print("[\(Date.now.timeIntervalSince1970)] Sent \(message)")
			}
		}
	}

	private func addToOutgoingQueue(_ messages: String...) {
		messages.forEach {
			outgoingMessageQueue.enqueue($0, quietly: !outgoingMessageQueue.isEmpty)
		}
	}

}
