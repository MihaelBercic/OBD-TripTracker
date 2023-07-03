//
//  ResponseBuilder.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import Foundation

class ResponseBuilder: ScopeFunctions {

	var totalDataLength: Int = 0xFFF
	private var data: [Int: [UInt8]] = [:]
	private var currentDataLength: Int = 0

	var isReady: Bool {
		currentDataLength >= totalDataLength
	}

	func insertData(_ frameIndex: Int, bytes: [UInt8]) {
		currentDataLength += bytes.count
		data.updateValue(bytes, forKey: frameIndex)
	}

	func combineData() -> [UInt8] {
		return data.sorted(by: { $0.key < $1.key }).flatMap { $0.value }
	}

}
