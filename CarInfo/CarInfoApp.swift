//
//  CarInfoApp.swift
//  CarInfo
//
//  Created by Mihael Bercic on 10/06/2023.
//
//

import CoreData
import SwiftUI

@main
struct CarInfoApp: App {

	private let bluetoothManager = BluetoothManager(interestedIn: [
		.engineRunTime, .ambientAirTemperature, .engineLoad,
		.engineCoolantTemperature, .fuelTankLevel,
		.engineSpeed, .vehicleSpeed,
	])

	@StateObject var tripDataManager = TripSingleton.shared.tripDataManager
	@Environment(\.scenePhase) var scenePhase

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, tripDataManager.container.viewContext)
		}.onChange(of: scenePhase) { scene in
			if scene == .active {
				UIApplication.shared.isIdleTimerDisabled = true
				TripSingleton.shared.startTheActivity()
			}
		}
	}
}
