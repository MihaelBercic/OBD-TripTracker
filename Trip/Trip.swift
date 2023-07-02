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
	var engineTemp = 00.0
	var ambientTemperature = 0.0
	var fuelTankLevel = 0.0

	init(start: Date = Date()) {
		self.start = start
	}

}

class TripSingleton {

	private let locationManager = LocationManager()
	let tripDataManager = TripDataManager()
	lazy var viewContext: NSManagedObjectContext = tripDataManager.container.viewContext

	static let shared: TripSingleton = .init()
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
		currentTrip?.use {
			$0.stoppedAt = .now
			let tripEntity = TripEntity(context: viewContext)
			tripEntity.averageSpeed = $0.speed
			tripEntity.distance = $0.distance
			tripEntity.timestamp = .now
			tripEntity.end = .now
			tripEntity.start = $0.start
			locations.forEach { location in
				let coordinate = location.coordinate
				let coordinateEntity = CoordinateEntity(context: self.viewContext)
				coordinateEntity.latitude = NSDecimalNumber(value: coordinate.latitude)
				coordinateEntity.longitude = NSDecimalNumber(value: coordinate.longitude)
				tripEntity.addToLocations(coordinateEntity)
			}
			do {
				viewContext.insert(tripEntity)
				try viewContext.save()
			} catch {
				print(error)
			}
		}
		liveActivityTimer?.invalidate()
		currentTrip = nil
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
	}

	func startTheActivity() {
		guard let trip = currentTrip else { return }
		if currentActivity != nil { return }
		let attributes = CarWidgetAttributes()
		let state = Activity<CarWidgetAttributes>.ContentState(trip: trip)
		currentActivity = try? Activity.request(attributes: attributes, contentState: state, pushType: nil)
	}

	private func processMeasurements() {
		while true {
			guard let measuredValue = measurementQueue.dequeue() else { continue }
			updateTrip(measuredValue: measuredValue)
		}
	}

}
