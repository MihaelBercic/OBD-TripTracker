//
//  MeasuredValue.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import Foundation

struct MeasuredValue: Equatable {
	let pid: PIDs
	let measurement: Measurement<Unit>
}
