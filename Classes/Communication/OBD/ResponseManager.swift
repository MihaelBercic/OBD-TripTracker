//
//  ResponseManager.swift
//  CarInfo
//
//  Created by Mihael Bercic on 28/06/2023.
//

import Foundation

class ResponseManager {

	private var measurementProcessingQueue: Queue<MeasuredValue> = TripSingleton.shared.measurementQueue
	private var activeBuilders: [Int: ResponseBuilder] = [:]
	private var byteBuffer = ByteBuffer()

	var canSend: Bool { activeBuilders.isEmpty }

	func prepare(message: String) {
		let bytes = message.split(separator: " ").compactMap { Int($0, radix: 16) }
		let canID = bytes[0]
		let secondByte = bytes[1]
		let isMessageSplit = (secondByte >> 4) > 0
		let frameIndex = isMessageSplit ? secondByte & 0xF : 0
		let isFirstFrame = !isMessageSplit || secondByte == 16
		let dataBytes = bytes.dropFirst(isFirstFrame ? (isMessageSplit ? 4 : 3) : 2).map { UInt8($0) }
		let activeBuilder = activeBuilders[canID] ?? ResponseBuilder()

		if isFirstFrame {
			let dataLength = bytes[isMessageSplit ? 2 : 1] - 1 // Response return indicator
			activeBuilder.totalDataLength = dataLength
		}

		activeBuilder.insertData(frameIndex, bytes: dataBytes)
		activeBuilders.updateValue(activeBuilder, forKey: canID)

		if activeBuilder.isReady {
			let dataToProcess = activeBuilder.combineData()
			byteBuffer.setData(Data(dataToProcess))
			activeBuilders.removeValue(forKey: canID)
			while byteBuffer.hasNext() {
				let id = byteBuffer.readNBytes(1)[0]
				guard let pid = PIDs(rawValue: id) else { return }
				guard let packet = Packets.packetMap[pid] else { return }
				let data = byteBuffer.readNBytes(packet.dataLength)
				let computedMeasurement = packet.compute(data)
				let measuredValue = MeasuredValue(pid: pid, measurement: computedMeasurement)
				measurementProcessingQueue.enqueue(measuredValue)
				print("Queued measurement: \(computedMeasurement)")
			}
		}
	}

	func clean() {
		activeBuilders.removeAll()
		
	}
}
