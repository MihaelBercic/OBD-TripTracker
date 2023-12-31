//
//  Trip.swift
//  CarInfo
//
//  Created by Mihael Bercic on 27/06/2023.
//

import ActivityKit
import CoreData
import CoreLocation
import NotificationCenter

public struct Trip: Codable, Hashable, ScopeFunctions {
	let start: Date

	var stoppedAt: Date? = nil

	var car = "XC70"
	var averageConsumption = 0.0
	var currentRpm = 0.0
	var distance = 0.0
    var litersUsed = 0.0
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

	let measurementQueue = Queue<MeasuredValue>()

	static let shared: TripSingleton = .init()

	private let geocoder = CLGeocoder()
	private let locationManager = LocationManager()

	private var liveActivityTimer: Timer?
	private(set) var currentTrip: Trip?
	private(set) var currentActivity: Activity<CarWidgetAttributes>?

	private var lastSpeedMeasurement: Date = .now
    private var lastAirFlowMeasurement: Date = .now

	private init() {
		Thread(block: processMeasurements).start()
	}

	func updateTrip(measuredValue: MeasuredValue) {
		let pid = measuredValue.pid
		let value = measuredValue.measurement.value
		print("🗒️ \t \(pid) => \(measuredValue.measurement)")

		if pid == .engineSpeed {
			let isEngineOn = value > 0
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
            case .massAirFlowSensor:
                // MAF(g/s) * 1/14.7 * 1L/710g = Fuel Consumption in L/s Units
                let timeDifference = abs(Date.now.distance(to: lastSpeedMeasurement))
                let litersPerSecond = value * 1/14.7 * 1/710
                let litersUsed = litersPerSecond * timeDifference
                $0.litersUsed += litersUsed
                Logger.info("Used += \(litersUsed)")
                lastAirFlowMeasurement = .now
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
			let content = ActivityContent(state: state, staleDate: nil)
			await activity.update(content)
		}
	}

	func stopTrip() {
		let locations = locationManager.stopTrackingLocation()
		defer {
			liveActivityTimer?.invalidate()
			currentTrip = nil
		}

		guard let trip = currentTrip else { return }
		guard let firstLocation = locations.first else { return }
		guard let lastLocation = locations.last else { return }

		// if trip.distance < 0.1 { return }
		Logger.info("Trip ended...")
		geocoder.reverseGeocodeLocation(firstLocation) { [self] startPlacemarks, _ in
			print("Start locations \(startPlacemarks?.count ?? 0)")
			guard let startPlacemark = startPlacemarks?[0] else { return }
			geocoder.reverseGeocodeLocation(lastLocation) { endPlacemarks, _ in
				guard let endPlacemark = endPlacemarks?[0] else { return }
				let startDate = trip.start
				let endDate: Date = .now
				let driveDuration = startDate.distance(to: endDate)
				let averageSpeed = (trip.distance * 1000 / driveDuration.magnitude) * 3.6
				Logger.info("Trip average speed \(averageSpeed)km/h")
                CoreDataManager.shared.performBackgroundTask { context in
                    TripEntity(context: context).apply { entity in
                        entity.end = .now
                        entity.start = trip.start
                        entity.averageSpeed = averageSpeed
                        entity.distance = trip.distance
                        entity.timestamp = .now
                        entity.fuelEnd = trip.fuelTankLevel.asDecimal
                        entity.fuelStart = trip.startFuelTankLevel.asDecimal
                        
                        entity.startCity = startPlacemark.locality ?? "Unknown"
                        entity.startCountry = startPlacemark.country ?? "Unknown"
                        entity.endCity = endPlacemark.locality ?? "Unknown"
                        entity.endCountry = endPlacemark.country ?? "Unknown"
                        
                        locations.dropFirst(10).forEach { location in
                            let coordinate = location.coordinate
                            let coordinateEntity = CoordinateEntity(context: context)
                            coordinateEntity.latitude = NSDecimalNumber(value: coordinate.latitude)
                            coordinateEntity.longitude = NSDecimalNumber(value: coordinate.longitude)
                            coordinateEntity.speed = Int16(location.speed.magnitude)
                            entity.addToLocations(coordinateEntity)
                        }
                        Logger.info("Stopped the trip: \(trip.distance)km")
                    }
                }
				Logger.info("Inserting the trip!")
                let formatter: DateComponentsFormatter = DateComponentsFormatter().apply { formatter in
                    formatter.unitsStyle = .abbreviated
                    formatter.zeroFormattingBehavior = .dropAll
                    formatter.allowedUnits = [.hour, .minute, .second]
                }
                
                let distance = trip.stoppedAt?.distance(to: trip.start) ?? .zero

                let notification = UNMutableNotificationContent().apply {
                    $0.title = "Car Trip"
                    $0.body = "Trip summary! 🚦\nDistance: \(trip.distance)km\nDuration \(formatter.string(from: distance) ?? "-")"
                    $0.sound = .default
                    $0.interruptionLevel = .timeSensitive
                }
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
                let uuid = UUID().uuidString
                let request = UNNotificationRequest(identifier: uuid, content: notification, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                center.add(request)
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
			}
		}
		print("Started the trip!")
        let notification = UNMutableNotificationContent().apply {
            $0.title = "Car Trip"
            $0.body = "Trip has started 🚦"
            $0.sound = .default
            $0.interruptionLevel = .timeSensitive
        }
        
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0 , repeats: false)
		let uuid = UUID().uuidString
		let request = UNNotificationRequest(identifier: uuid, content: notification, trigger: trigger)
		let center = UNUserNotificationCenter.current()
		center.add(request)
	}

	func startTheActivity() {
		guard let trip = currentTrip else { return }
		if currentActivity != nil { return }
		let attributes = CarWidgetAttributes()
		let state = Activity<CarWidgetAttributes>.ContentState(trip: trip)
		let content = ActivityContent(state: state, staleDate: nil)
		currentActivity = try? Activity.request(attributes: attributes, content: content, pushType: nil)
		Logger.info("Started the activity.")
	}

	private func processMeasurements() {
		while true {
			guard let measuredValue = measurementQueue.dequeue() else { continue }
			updateTrip(measuredValue: measuredValue)
		}
	}

}
