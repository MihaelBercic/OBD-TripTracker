//
//  CarInfoApp.swift
//  CarInfo
//
//  Created by Mihael Bercic on 10/06/2023.
//
//

import CoreData
import NotificationCenter
import SwiftUI

@main
struct CarInfoApp: App {

	private let bluetoothManager = BluetoothManager(interestedIn: [
		.engineRunTime, .ambientAirTemperature, .engineLoad,
		.engineCoolantTemperature, .fuelTankLevel,
        .engineSpeed, .vehicleSpeed, .massAirFlowSensor
	])

	@Environment(\.scenePhase) var scenePhase

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
				.onAppear {
					UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
						if let error = error {
							print(error)
						}
					}
				}
		}.onChange(of: scenePhase) { scene in
			if scene == .active {
				UIApplication.shared.isIdleTimerDisabled = true
				TripSingleton.shared.startTheActivity()
			}
		}
	}
}
