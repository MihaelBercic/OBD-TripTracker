//
//  PIDs.swift
//  CarInfo
//
//  Created by Mihael Bercic on 26/06/2023.
//

import Foundation

enum Packets {

	public static let engineLoad = Packet(id: .engineLoad, dataLength: 1) { data in
		let measuredValue = Double(data[0])
		return Measurement(value: measuredValue / 2.55, unit: Unit(symbol: "%"))
	}

	public static let engineSpeed = Packet(id: .engineSpeed, dataLength: 2) { data in
		let computedValue = (256 * Int(data[0]) + Int(data[1])) / 4
		return Measurement(value: Double(computedValue), unit: Unit(symbol: "RPM"))
	}

	public static let vehicleSpeed = Packet(id: .vehicleSpeed, dataLength: 1) { data in
		Measurement(value: Double(data[0]), unit: UnitSpeed.kilometersPerHour)
	}

	public static let engineRunTime = Packet(id: .engineRunTime, dataLength: 2) { data in
		let doubleMapped = data[0 ... 1].map { Double($0) }
		return Measurement(value: 256.0 * doubleMapped[0] + doubleMapped[1], unit: UnitDuration.seconds)
	}

	public static let fuelTankLevel = Packet(id: .fuelTankLevel, dataLength: 1) { data in
		Measurement(value: 100 * Double(data[0]) / 255.0, unit: Unit(symbol: "%"))
	}

	public static let engineCoolantTemperature = Packet(id: .engineCoolantTemperature, dataLength: 1) { data in
		Measurement(value: Double(data[0]) - 40.0, unit: UnitTemperature.celsius)
	}

	public static let intakeAirTemperature = Packet(id: .intakeAirTemperature, dataLength: 1) { data in
		Measurement(value: Double(data[0]) - 40.0, unit: UnitTemperature.celsius)
	}

	public static let throttlePosition = Packet(id: .throttlePosition, dataLength: 1) { data in
		Measurement(value: 100 * Double(data[0]) / 255.0, unit: Unit(symbol: "%"))
	}

	public static let ambientAirTemperature = Packet(id: .ambientAirTemperature, dataLength: 1) { data in
		Measurement(value: Double(data[0]) - 40.0, unit: UnitTemperature.celsius)
	}

	public static let engineFuelRate = Packet(id: .engineFuelRate, dataLength: 2) { data in
		let doubleMapped = data[0 ... 1].map { Double($0) }
		return Measurement(value: (256 * doubleMapped[0] + doubleMapped[1]) / 20, unit: Unit(symbol: "L/h"))
	}

	public static let odometer = Packet(id: .odometer, dataLength: 4) { data in
		let mapped = data.map { Int($0) }
		let distance = (mapped[0] * 2 ^ 24) + (mapped[1] * 2 ^ 16) + (mapped[2] * 2 ^ 8) + mapped[3]
		return Measurement(value: Double(distance) / 10.0, unit: UnitLength.kilometers)
	}
    
    public static let massAirFlowSensor = Packet(id: .massAirFlowSensor, dataLength: 2) { data in
        let mapped = data.map {Double($0)}
        let flowRate = (256.0 * mapped[0] + mapped[1]) / 100.0
        return Measurement(value: flowRate, unit: Unit(symbol: "g/s"))
    }
    
    

	public static let packetMap: [PIDs: Packet] = [
		.engineSpeed: Packets.engineSpeed,
		.engineLoad: Packets.engineLoad,
		.odometer: Packets.odometer,
		.engineFuelRate: Packets.engineFuelRate,
		.ambientAirTemperature: Packets.ambientAirTemperature,
		.throttlePosition: Packets.throttlePosition,
		.intakeAirTemperature: Packets.intakeAirTemperature,
		.engineCoolantTemperature: Packets.engineCoolantTemperature,
		.fuelTankLevel: Packets.fuelTankLevel,
		.engineRunTime: Packets.engineRunTime,
		.vehicleSpeed: Packets.vehicleSpeed,
        .massAirFlowSensor: Packets.massAirFlowSensor
	]
}
