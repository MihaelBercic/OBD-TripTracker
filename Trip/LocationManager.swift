//
//  LocationManager.swift
//  CarInfo
//
//  Created by Mihael Bercic on 29/06/2023.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, CLLocationManagerDelegate {

	let locationManager = CLLocationManager()
	private var locationUpdates: [CLLocation] = []

	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.pausesLocationUpdatesAutomatically = true
		locationManager.desiredAccuracy = .greatestFiniteMagnitude
		print("Initialised location manager!")
	}

	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if manager.authorizationStatus == .notDetermined {
			manager.requestAlwaysAuthorization()
		}
	}

	func startTrackingLocation() {
		locationUpdates = []
		locationManager.startUpdatingLocation()
	}

	func stopTrackingLocation() -> [CLLocation] {
		let locations = locationUpdates
		locationUpdates = []
		locationManager.stopUpdatingLocation()
		return locations
	}

	func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		locationUpdates.append(contentsOf: locations)
	}

}
