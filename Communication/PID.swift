//
//  PID.swift
//  CarInfo
//
//  Created by Mihael Bercic on 24/06/2023.
//

import Foundation

public struct PID {
	var id: UInt8
	var dataLength: Int
	var compute: ([UInt8]) -> Measurement<Unit>
}
