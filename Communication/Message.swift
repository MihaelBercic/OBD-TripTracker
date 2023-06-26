//
//  Message.swift
//  CarInfo
//
//  Created by Mihael Bercic on 26/06/2023.
//

import Foundation

public struct Message {
	let sid: String
	let requiredDataLength: Int
	var responseData: [String] = []
	var responseMeasurements: [UInt8: Measurement] = [:]
	var pids: [PID] = []

	var canBeProcessed: Bool {
		responseData.count >= requiredDataLength
	}

	init(sid: String, pids: [PID]) {
		self.sid = sid
		self.pids.append(contentsOf: pids)
		requiredDataLength = pids.count + pids.reduce(0) { total, pid in
			total + pid.dataLength
		}
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

	var encodedData: String {
		"\(sid) \(pids.map { String(format: "%02X", $0.id) }.joined())"
	}
}

extension Message {
	init(sid: String, pids: PID...) {
		self.init(sid: sid, pids: pids)
	}
}
