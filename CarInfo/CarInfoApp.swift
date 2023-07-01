//
//  CarInfoApp.swift
//  CarInfo
//
//  Created by Mihael Bercic on 10/06/2023.
//
//

import SwiftUI

@main
struct CarInfoApp: App {

	private let bluetoothManager = BluetoothManager(interestedIn: [
		.engineRunTime, .ambientAirTemperature, .engineLoad,
		.engineCoolantTemperature, .fuelTankLevel,
		.engineSpeed, .vehicleSpeed,
	])

	@Environment(\.scenePhase) private var scenePhase

	var body: some Scene {
		WindowGroup {
			ContentView()
		}.onChange(of: scenePhase) { scene in
			if scene == .active {
				UIApplication.shared.isIdleTimerDisabled = true
				TripSingleton.shared.startTheActivity()
			}
		}
	}
}