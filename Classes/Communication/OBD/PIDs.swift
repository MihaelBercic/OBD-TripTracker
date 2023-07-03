//
//  PIDs.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import Foundation

public enum PIDs: UInt8 {
	case engineLoad = 0x04
	case engineSpeed = 0x0C
	case vehicleSpeed = 0x0D
	case engineRunTime = 0x1F
	case fuelTankLevel = 0x2F
	case engineCoolantTemperature = 0x05
	case intakeAirTemperature = 0x0F
	case throttlePosition = 0x11
	case ambientAirTemperature = 0x46
	case engineFuelRate = 0x5E
	case odometer = 0xA6

}
