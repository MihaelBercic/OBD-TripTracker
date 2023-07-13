//
//  MapView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 09/07/2023.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {

	private let path = [CLLocation(latitude: 46.02550, longitude: 14.54126),
	                    CLLocation(latitude: 46.02531, longitude: 14.54096),
	                    CLLocation(latitude: 46.02504, longitude: 14.54070),
	                    CLLocation(latitude: 46.02489, longitude: 14.54038),
	                    CLLocation(latitude: 46.02467, longitude: 14.54008),
	                    CLLocation(latitude: 46.02450, longitude: 14.53948)]

	@Binding var currentTrip: TripEntity?

	func makeCoordinator() -> MapViewDelegate {
		return MapViewDelegate()
	}

	func updateUIView(_ x: UIViewType, context: Context) {
		guard let mapView = x as? MKMapView else { return }
		guard let currentTrip = currentTrip else { return }
		mapView.delegate = context.coordinator
		mapView.pointOfInterestFilter = .excludingAll
		guard let delegate = mapView.delegate as? MapViewDelegate else { return }
		delegate.setCurrentTrip(mapView: mapView, currentTrip)
	}

	func makeUIView(context _: Context) -> some UIView {
		let mapView = MKMapView()
		mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
		print("Made UI View")
		return mapView
	}

}

class MapViewDelegate: NSObject, MKMapViewDelegate {

	private(set) var currentTrip: TripEntity? = nil
	private(set) var mapView: MKMapView? = nil

	private var path: [CLLocation] = []
	private var animationTimer: Timer? = nil
	private var newRenderNeeded: Bool = false
	private var canRender: Bool = false
	private var currentTimer: Timer? = nil
	private var currentSegment = 1
	private var canRenderSpeed: Bool = false

	private var previousPolyline: MKPolyline? = nil

	func setCurrentTrip(mapView: MKMapView, _ newTrip: TripEntity) {
		newRenderNeeded = currentTrip != newTrip
		currentTrip = newTrip
		self.mapView = mapView

		if newRenderNeeded {
			currentTimer?.invalidate()
			path = newTrip.locations.map { coordinate in
				let latitude = coordinate.latitude.doubleValue
				let longitude = coordinate.longitude.doubleValue
				let speed = coordinate.speed

				let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
				let altitude = CLLocationDistance()
				return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: CLLocationAccuracy(), verticalAccuracy: CLLocationAccuracy(), course: 0.0, speed: Double(speed), timestamp: .now)
			}
			animateTrip(mapView: mapView)
		}
	}

	private func animateTrip(mapView: MKMapView) {
		let coordinates = path.map { $0.coordinate }
		let totalPolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
		mapView.setVisibleMapRect(totalPolyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50.0, left: 50.0, bottom: 500.0, right: 50.0), animated: true)
	}

	func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
		if newRenderNeeded {
			let coordinates = path.map { $0.coordinate }
			let segmentSize = coordinates.count / 20

			currentSegment = 1
			canRenderSpeed = false
			previousPolyline = nil
			currentTimer?.invalidate()
			newRenderNeeded = false
			mapView.removeOverlays(mapView.overlays)
			currentTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] timer in
				let currentMaxIndex = min(coordinates.count - 1, currentSegment * segmentSize)
				let minimumIndex = max(currentMaxIndex - segmentSize, 0)
				let forSpeedComputation = Array(path[minimumIndex ... currentMaxIndex])

				let averageSpeed = forSpeedComputation.enumerated().reduce(0.0) { total, current in
					let index = current.0
					let location = current.1
					if index >= forSpeedComputation.endIndex - 1 { return total / Double(forSpeedComputation.count) }
					return total + location.speed
				}

				// averageSpeed = Double.random(in: 0.0 ... 2 * 45.0)
				var description = "systemGreen"
				if averageSpeed == 0.0 {
					description = "systemBlue"
				} else if averageSpeed <= 0.5 {
					description = "black"
				} else if averageSpeed <= 15 {
					description = "systemDarkRed"
				} else if averageSpeed <= 30 {
					description = "systemRed"
				} else if averageSpeed <= 60 {
					description = "systemDarkOrange"
				} else if averageSpeed <= 90 {
					description = "systemOrange"
				} else if averageSpeed <= 110 {
					description = "systemGreen"
				} else if averageSpeed <= 110 {
					description = "systemLightGreen"
				}

				let polyline = MKPolyline(coordinates: forSpeedComputation.map { $0.coordinate }, count: forSpeedComputation.count)
				let border = MKPolyline(coordinates: forSpeedComputation.map { $0.coordinate }, count: forSpeedComputation.count)

				let isLast = currentMaxIndex >= coordinates.count - 1
				canRenderSpeed = isLast

				polyline.subtitle = description
				border.title = "border"
				border.subtitle = description

				if let previousPolyline = previousPolyline {
					mapView.insertOverlay(border, below: previousPolyline)
				} else {
					mapView.addOverlay(border, level: .aboveLabels)
				}
				mapView.addOverlay(polyline, level: .aboveLabels)
				previousPolyline = polyline

				if isLast {
					timer.invalidate()
				}
				currentSegment += 1
			}
		}
	}

	func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		guard let polyline = overlay as? MKPolyline else {
			return MKOverlayRenderer()
		}
		let percentageChange = 20.0
		var color: UIColor = .systemGreen
		switch polyline.subtitle {
		case "black":
			color = .black
		case "systemDarkRed":
			color = .systemRed.darker(by: percentageChange)!
		case "systemRed":
			color = .systemRed
		case "systemDarkOrange":
			color = .systemOrange.darker(by: percentageChange)!
		case "systemOrange":
			color = .systemOrange
		case "systemGreen":
			color = .systemGreen
		case "systemLightGreen":
			color = .systemGreen.lighter(by: percentageChange)!
		default:
			color = .systemBlue
		}

		if polyline.title != "border" {
			let renderer = MKPolylineRenderer(polyline: polyline)
			renderer.lineWidth = 3
			renderer.strokeColor = color
			renderer.lineCap = .round
			return renderer
		}

		let borderColor = UIScreen.main.traitCollection.userInterfaceStyle == .light ? color.darker(by: percentageChange)! : color.lighter(by: percentageChange)!
		let gradientRenderer = MKPolylineRenderer(polyline: polyline)
		gradientRenderer.lineWidth = 5
		gradientRenderer.lineCap = .round
		gradientRenderer.strokeColor = borderColor
		return gradientRenderer
	}

}

struct MapView_Previews: PreviewProvider {

	@State static var currentTrip: TripEntity? = TripEntity(context: CoreDataManager.shared.viewContext).apply { entity in
		entity.start = .now
		entity.end = .now
		entity.timestamp = .now
		[
			CLLocation(latitude: 46.02550, longitude: 14.54126),
			CLLocation(latitude: 46.02531, longitude: 14.54096),
			CLLocation(latitude: 46.02504, longitude: 14.54070),
			CLLocation(latitude: 46.02489, longitude: 14.54038),
			CLLocation(latitude: 46.02467, longitude: 14.54008),
			CLLocation(latitude: 46.02450, longitude: 14.53948),
		].map { location in
			CoordinateEntity(context: CoreDataManager.shared.viewContext).apply {
				$0.latitude = location.coordinate.latitude.asDecimal
				$0.longitude = location.coordinate.longitude.asDecimal
			}
		}
		.forEach { coord in
			entity.addToLocations(coord)
		}
	}

	static var previews: some View {
		MapView(currentTrip: $currentTrip)
	}
}
