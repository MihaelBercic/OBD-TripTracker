//
//  ByteBuffer.swift
//  CarInfo
//
//  Created by Mihael Bercic on 26/06/2023.
//

import Foundation

class ByteBuffer {
	private var data: Data
	private var index: Int = 0

	init(_ data: Data = .init()) {
		self.data = data
	}

	func setData(_ data: Data) {
		self.data = data
		index = 0
	}

	func hasNext() -> Bool {
		index < data.count - 1
	}

	func readNBytes(_ n: Int) -> [UInt8] {
		let readData = data.subdata(in: index ..< index + n).map { $0 }
		index += n
		return readData
	}
}
