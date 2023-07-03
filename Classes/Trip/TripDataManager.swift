//
//  TripDataManager.swift
//  CarInfo
//
//  Created by Mihael Bercic on 01/07/2023.
//

import CoreData
import Foundation

class TripDataManager: NSObject, ObservableObject {

	@Published var tripHistory: [TripEntity] = []

	let container = NSPersistentContainer(name: "CarInfo")

	override init() {
		super.init()
		print("Initialised Trip Data Manager...")
		container.loadPersistentStores { _, error in
			if let error = error {
				print("Error with data loading \(error)")
			}
		}
	}

}
