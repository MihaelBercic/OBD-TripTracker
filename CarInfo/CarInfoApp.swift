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
		.engineSpeed, .vehicleSpeed,
	])

	@Environment(\.scenePhase) var scenePhase

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
				.onAppear {
					UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { allowed, error in
						print("Complete: \(allowed) \(error)")
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
