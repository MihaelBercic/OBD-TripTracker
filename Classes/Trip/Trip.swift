//
//  Trip.swift
//  CarInfo
//
//  Created by Mihael Bercic on 27/06/2023.
//

import ActivityKit
import CoreData
import CoreLocation

public struct Trip: Codable, Hashable, ScopeFunctions {
	let start: Date

	var stoppedAt: Date? = nil

	var car = "XC70"
	var averageConsumption = 0.0
	var currentRpm = 0.0
	var distance = 0.0
	var speed = 0.0
	var engineTemp = 0.0
	var ambientTemperature = 0.0
	var fuelTankLevel = 0.0 {
		didSet {
			if startFuelTankLevel == 0.0 {
				startFuelTankLevel = fuelTankLevel
			}
		}
	}

	var startFuelTankLevel = 0.0

	init(start: Date = Date()) {
		self.start = start
	}

}

class TripSingleton {

	static let shared: TripSingleton = .init()

	private let geocoder = CLGeocoder()

	private let locationManager = LocationManager()
	lazy var tripDataManager = TripDataManager()
	lazy var viewContext: NSManagedObjectContext = tripDataManager.container.viewContext

	let measurementQueue = Queue<MeasuredValue>()
	private var liveActivityTimer: Timer?
	private(set) var currentTrip: Trip?
	private(set) var currentActivity: Activity<CarWidgetAttributes>?

	private var lastSpeedMeasurement: Date = .now

	private init() {
		Thread(block: processMeasurements).start()
	}

	func updateTrip(measuredValue: MeasuredValue) {
		let pid = measuredValue.pid
		let value = measuredValue.measurement.value
		print("🗒️ \t \(pid) => \(measuredValue.measurement)")

		if pid == .engineSpeed {
			let isEngineOn = value > 0
			print("Engine is on: \(isEngineOn) and current trip exists \(currentTrip != nil)")
			if isEngineOn, currentTrip == nil {
				startTrip()
			}

			if !isEngineOn, currentTrip != nil {
				stopTrip()
			}
		}

		currentTrip?.use {
			switch pid {
			case .engineSpeed:
				$0.currentRpm = value
			case .vehicleSpeed:
				let timeDifference = abs(Date.now.distance(to: lastSpeedMeasurement))
				let speedKMH = value
				let speedMS = speedKMH / 3.6
				let movedMeters = speedMS * timeDifference
				let movedKilometers = movedMeters / 1000.0
				$0.speed = value
				$0.distance += movedKilometers
				lastSpeedMeasurement = .now
			case .fuelTankLevel:
				$0.fuelTankLevel = value
			case .engineCoolantTemperature:
				$0.engineTemp = value
			case .ambientAirTemperature:
				$0.ambientTemperature = value
			default: ()
			}
		}
	}

	func updateActivity() {
		Task {
			guard let trip = currentTrip else { return }
			guard let activity = currentActivity else { return }
			let state = Activity<CarWidgetAttributes>.ContentState(trip: trip)
			await activity.update(using: state)
		}
	}

	func stopTrip() {
		let locations = locationManager.stopTrackingLocation()
		defer {
			liveActivityTimer?.invalidate()
			currentTrip = nil
		}

		guard let firstLocation = locations.first else { return }
		guard let lastLocation = locations.last else { return }
		guard var trip = currentTrip else { return }

		// if trip.distance < 0.1 { return }

		geocoder.reverseGeocodeLocation(firstLocation) { [self] startPlacemarks, _ in
			print("Start locations \(startPlacemarks?.count ?? 0)")
			guard let startPlacemark = startPlacemarks?[0] else { return }
			geocoder.reverseGeocodeLocation(lastLocation) { [self] endPlacemarks, _ in
				print("End locations \(endPlacemarks?.count ?? 0)")
				guard let endPlacemark = endPlacemarks?[0] else { return }

				print("Start \(startPlacemark.locality), \(startPlacemark.country)")
				print("End \(endPlacemark.locality), \(endPlacemark.country)")

				let tripEntity = TripEntity(context: viewContext).apply { entity in
					entity.end = .now
					entity.start = trip.start
					entity.averageSpeed = trip.speed
					entity.distance = trip.distance
					entity.timestamp = .now
					entity.fuelEnd = trip.fuelTankLevel.asDecimal
					entity.fuelStart = trip.startFuelTankLevel.asDecimal

					entity.startCity = startPlacemark.locality ?? "Unknown"
					entity.startCountry = startPlacemark.country ?? "Unknown"
					entity.endCity = endPlacemark.locality ?? "Unknown"
					entity.endCountry = endPlacemark.country ?? "Unknown"

					print("Set entity values to: \(entity.startCity), \(entity.startCountry) -> \(entity.endCity), \(entity.endCountry)")

					locations.forEach { location in
						let coordinate = location.coordinate
						let coordinateEntity = CoordinateEntity(context: self.viewContext)
						coordinateEntity.latitude = NSDecimalNumber(value: coordinate.latitude)
						coordinateEntity.longitude = NSDecimalNumber(value: coordinate.longitude)
						entity.addToLocations(coordinateEntity)
					}
					print("Stopped the trip: \(trip.distance)km")
				}
				do {
					viewContext.insert(tripEntity)
					try viewContext.save()
					print("Saved the trip!")
				} catch {
					print(error)
				}
			}
		}
	}

	func startTrip() {
		lastSpeedMeasurement = .now
		currentTrip = Trip()
		startTheActivity()
		locationManager.startTrackingLocation()
		DispatchQueue.main.async { [weak self] in
			self?.liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
				TripSingleton.shared.updateActivity()
				print("Timer is running!")
			}
		}
		print("Started the trip!")
	}

	func startTheActivity() {
		guard let trip = currentTrip else { return }
		if currentActivity != nil { return }
		let attributes = CarWidgetAttributes()
		let state = Activity<CarWidgetAttributes>.ContentState(trip: trip)
		currentActivity = try? Activity.request(attributes: attributes, contentState: state, pushType: nil)
		print("Started the activity.")
	}

	private func processMeasurements() {
		while true {
			guard let measuredValue = measurementQueue.dequeue() else { continue }
			updateTrip(measuredValue: measuredValue)
		}
	}

}
