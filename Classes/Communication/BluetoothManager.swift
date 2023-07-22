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
	private var messageInterval = 0.1

	private let adapterName = "IOS-Vlink"
	private let advertisedUUID = CBUUID(string: "18F0")
	private let serviceUUID = CBUUID(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")
	private let characteristicUUID = CBUUID(string: "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F")
	private let trimmingCharacterSet: CharacterSet = [" ", "\r", "\n", ">"]

	private var manager: CBCentralManager? = nil
	private var adapter: CBPeripheral? = nil
	private var responseManager: ResponseManager = .init()
	private let outgoingQueue: Queue<Message> = .init()

	init(interestedIn: [PIDs] = []) {
		super.init()
		self.interestedIn.append(contentsOf: interestedIn)
		manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "central-manager-identifier"])
		Logger.info("🛜 Bluetooth Manager set up")
	}

	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		if central.state == .poweredOn {
			let isConnected = adapter?.state == .connected
			Logger.info("Updated state and is connected: \(isConnected)")
			if isConnected {
				adapter?.discoverServices([serviceUUID])
			} else {
				Logger.info("📡 Scanning for peripherals...")
				central.scanForPeripherals(withServices: [advertisedUUID])
			}
		}
	}

	func centralManager(_ manager: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
		if peripheral.name != "IOS-Vlink" { return }
		manager.stopScan()
		Logger.info("📍 Discovered our adapter!")
		adapter = peripheral.apply {
			$0.delegate = self
			manager.connect($0)
		}
	}

	func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
		Logger.info("✅ Connected to our adapter!")
		adapter = peripheral
		peripheral.discoverServices([serviceUUID])
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
		guard let importantService = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else { return }
		Logger.info("💭 Discovered the important service!")
		peripheral.discoverCharacteristics([characteristicUUID], for: importantService)
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
		guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else { return }
		Logger.info("💭 Discovered the important characteristic!")
		let pidsChunked = interestedIn.chunked(into: 2)

		peripheral.setNotifyValue(true, for: characteristic)
		outgoingQueue.clear()
		addToQueue(
			// "AT Z",
			"AT WS",
			"AT FE",
			"AT E0",
			"AT SP 0",
			"AT L0",
			"AT H1", repeats: false
		)

		pidsChunked.forEach {
			let request = Request(sid: "01", pids: $0)
			addToQueue(request.encodedRequest, repeats: true)
		}
		sendMessage(forCharacteristic: characteristic)
	}

	func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
		guard let data = characteristic.value else { return }
		guard let encodedData = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: trimmingCharacterSet) else { return }

		let shouldIgnoreResponse = encodedData.count <= 1 || encodedData.contains(/SEARCHING/)
		// print("🔊 \(encodedData)")
		if shouldIgnoreResponse { return }
		messageInterval = 0.5

		if encodedData.contains(/NO|UNABLE|ERROR|STOPPED/) {
			Logger.error(encodedData)
			messageInterval = 1
			responseManager.clean()
			sendMessage(forCharacteristic: characteristic)
		} else {
			if encodedData.split(separator: " ").count < 3 {
				Logger.debug("Short data: |\(encodedData)|")
				sendMessage(forCharacteristic: characteristic)
				return
			}

			let lines = encodedData.split(whereSeparator: \.isNewline)
			lines.filter { !$0.isEmpty && $0.contains(" ") }.forEach {
				responseManager.prepare(message: String($0))
			}

			if responseManager.canSend {
				sendMessage(forCharacteristic: characteristic)
			}
		}
	}

	func peripheral(_: CBPeripheral, didReadRSSI rssiValue: NSNumber, error _: Error?) {
		if rssiValue.decimalValue < -80 {
			// messageInterval = 5
			// Logger.info("Increasing message interval to 10 (RSSI)")
		}
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: Error?) {
		central.connect(peripheral)
		TripSingleton.shared.stopTrip()
		Logger.info("Will try to reconnect!")
	}

	func centralManager(_ central: CBCentralManager, willRestoreState state: [String: Any]) {
		Logger.info("Will restore state!")
		guard let restoredPeripherals = state[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
		Logger.info("There are \(restoredPeripherals.count) restored peripherals.")
		guard let ourAdapter = restoredPeripherals.first(where: { $0.name == adapterName }) else { return }
		var adapterState = ""
		switch ourAdapter.state {
		case .disconnected:
			adapterState = "disconnected"
		case .connecting:
			adapterState = "connecting"
		case .connected:
			adapterState = "connected"
		default:
			adapterState = "disconnecting"
		}
		Logger.info("Restoring state, adapter exists \(adapterState)!")
		adapter = ourAdapter.apply {
			$0.delegate = self
			if $0.state == .connected {
				$0.discoverServices([serviceUUID])
			} else if $0.state == .disconnected {
				central.connect($0)
			}
		}
	}

	private func sendMessage(forCharacteristic: CBCharacteristic) {
		Logger.info("Sending message!")
		guard let adapter = adapter else { return }
		guard let message = outgoingQueue.peek() else { return }
		DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + messageInterval) { [self] in
			adapter.writeValue(message.data, for: forCharacteristic, type: .withoutResponse)
			Logger.info("Sent message!")

			if message.repeats {
				outgoingQueue.moveToTheBack()
			}
		}
	}

	private func addToQueue(_ messages: String..., repeats: Bool) {
		messages.forEach { command in
			let encodedData = Data("\(command)\r".utf8)
			let message = Message(data: encodedData, repeats: repeats)
			outgoingQueue.enqueue(message)
		}
	}

}

class Message: Equatable {

	let data: Data
	let repeats: Bool

	init(data: Data, repeats: Bool) {
		self.data = data
		self.repeats = repeats
	}

	static func == (lhs: Message, rhs: Message) -> Bool {
		lhs.data.hashValue == rhs.data.hashValue
	}
}
