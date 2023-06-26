//
//  PID.swift
//  CarInfo
//
//  Created by Mihael Bercic on 24/06/2023.
//

import Foundation

public struct PID {
	// associatedtype T: Unit

	var id: UInt8
	var dataLength: Int
	var compute: ([UInt8]) -> Measurement<Unit>
}

public struct PIDs {
	public static let engineLoad = PID(id: 0x04, dataLength: 1) { data in
		let measuredValue = Double(data[0])
		return Measurement(value: measuredValue / 2.55, unit: Unit(symbol: "%"))
	}

	public static let engineSpeed = PID(id: 0x0C, dataLength: 2) { data in
		let computedValue = (256 * Int(data[0]) + Int(data[1])) / 4
		return Measurement(value: Double(computedValue), unit: Unit(symbol: "RPM"))
	}

	public static let vehicleSpeed = PID(id: 0x0D, dataLength: 1) { data in
		Measurement(value: Double(data[0]), unit: UnitSpeed.kilometersPerHour)
	}

	public static let engineRunTime = PID(id: 0x1F, dataLength: 2) { data in
		let doubleMapped = data[0...1].map {
			Double($0)
		}
		return Measurement(value: 256.0 * doubleMapped[0] + doubleMapped[1], unit: UnitDuration.seconds)
	}

	public static let fuelTankLevel = PID(id: 0x2F, dataLength: 1) { data in
		Measurement(value: 100 * Double(data[0]) / 255.0, unit: Unit(symbol: "%"))
	}

	public static let engineCoolantTemperature = PID(id: 0x05, dataLength: 1) { data in
		Measurement(value: Double(data[0]) - 40.0, unit: UnitTemperature.celsius)
	}

	public static let intakeAirTemperature = PID(id: 0x0F, dataLength: 1) { data in
		Measurement(value: Double(data[0]) - 40.0, unit: UnitTemperature.celsius)
	}

	public static let throttlePosition = PID(id: 0x11, dataLength: 1) { data in
		Measurement(value: 100 * Double(data[0]) / 255.0, unit: Unit(symbol: "%"))
	}

	public static let ambientAirTemperature = PID(id: 0x46, dataLength: 1) { data in
		Measurement(value: Double(data[0]) - 40.0, unit: UnitTemperature.celsius)
	}

	public static let engineFuelRate = PID(id: 0x5E, dataLength: 2) { data in
		let doubleMapped = data[0...1].map {
			Double($0)
		}
		return Measurement(value: (256 * doubleMapped[0] + doubleMapped[1]) / 20, unit: UnitFuelEfficiency.litersPer100Kilometers)
	}

	public static let odometer = PID(id: 0xA6, dataLength: 4) { data in
		let mapped = data.map {
			Int($0)
		}
		let distance = (mapped[0] * 2 ^ 24) + (mapped[1] * 2 ^ 16) + (mapped[2] * 2 ^ 8) + mapped[3]
		return Measurement(value: Double(distance) / 10.0, unit: UnitLength.kilometers)
	}
}
