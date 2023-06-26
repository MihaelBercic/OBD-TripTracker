//
//  Message.swift
//  CarInfo
//
//  Created by Mihael Bercic on 26/06/2023.
//

import CoreBluetooth
import Foundation

public struct Message: Equatable {

	let sid: String
	let requiredDataLength: Int
	let encodedRequest: String
	let characteristic: CBCharacteristic?
	var responseData: [String] = []
	var responseMeasurements: [UInt8: Measurement] = [:]
	var pids: [PID] = []

	init(_ characteristic: CBCharacteristic? = nil, sid: String, pids: [PID]) {
		self.characteristic = characteristic
		self.sid = sid
		self.pids.append(contentsOf: pids)
		requiredDataLength = pids.count + pids.reduce(0) { total, pid in
			total + pid.dataLength
		}
		encodedRequest = "\(sid) \(pids.map { String(format: "%02X", $0.id) }.joined())"
	}

	var canBeProcessed: Bool {
		responseData.count >= requiredDataLength
	}

	mutating func processMessage() {
		if !canBeProcessed { return }
		let data = Data(responseData.map { encoded in UInt8(encoded, radix: 16)! })
		let byteBuffer = ByteBuffer(data)

		while byteBuffer.hasNext() {
			let id = byteBuffer.readNBytes(1)[0]
			guard let pid = pids.first(where: { pid in pid.id == id }) else { return }
			let data = byteBuffer.readNBytes(pid.dataLength)
			let computedMeasurement = pid.compute(data)
			responseMeasurements[id] = computedMeasurement
		}
	}

	func freshCopy() -> Message {
		Message(characteristic, sid: sid, pids: pids)
	}

	mutating func reset() {
		responseData = []
		responseMeasurements = [:]
	}

	public static func == (lhs: Message, rhs: Message) -> Bool {
		lhs.encodedRequest == rhs.encodedRequest
	}

}

extension Message {
	init(_ characteristic: CBCharacteristic? = nil, sid: String, pids: PID...) {
		self.init(characteristic, sid: sid, pids: pids)
	}
}
