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
	private var colors: [UIColor] = [.red]
	private var locations: [CGFloat] = [0.5]
	private var animationTimer: Timer? = nil
	private var newRenderNeeded: Bool = false
	private var canRender: Bool = false
	private var currentTimer: Timer? = nil
	private var currentSegment = 1
	private var canRenderSpeed: Bool = false

	func setCurrentTrip(mapView: MKMapView, _ newTrip: TripEntity) {
		print("Setting new trip: \(newTrip.hash)")
		newRenderNeeded = currentTrip != newTrip
		currentTrip = newTrip
		self.mapView = mapView

		if newRenderNeeded {
			path = newTrip.locations.map { CLLocation(latitude: $0.latitude.doubleValue, longitude: $0.longitude.doubleValue) }
			animateTrip(mapView: mapView)
		}
	}

	private func animateTrip(mapView: MKMapView) {
		colors = []
		locations = []
		currentTimer?.invalidate()
		let coordinates = path.map { $0.coordinate }
		let totalPolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
		mapView.setVisibleMapRect(totalPolyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 0.0, left: 100.0, bottom: 400.0, right: 100.0), animated: true)
		mapView.removeOverlays(mapView.overlays)
	}

	func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
		print("Did change and \(newRenderNeeded)")
		if newRenderNeeded {
			let coordinates = path.map { $0.coordinate }
			let segmentSize = coordinates.count / 20
			currentSegment = 1
			canRenderSpeed = false
			currentTimer?.invalidate()
			currentTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] timer in
				let currentMaxIndex = min(coordinates.count - 1, currentSegment * segmentSize)
				let toDraw = coordinates[0 ... currentMaxIndex]
				let forSpeedComputation = Array(self.path[currentMaxIndex - segmentSize ... currentMaxIndex])
				let currentPercentage = Double(currentMaxIndex) / Double(coordinates.count)

				let averageDistance = forSpeedComputation.enumerated().reduce(0.0) { total, current in
					let index = current.0
					let location = current.1
					if index >= forSpeedComputation.endIndex - 1 { return total / Double(forSpeedComputation.count) }
					let nextLocation = forSpeedComputation[index + 1]
					return total + location.distance(from: nextLocation)
				}

				var colorToAdd: UIColor = .systemGreen

				if averageDistance < 5 {
					colorToAdd = .systemRed
				} else if averageDistance < 10 {
					colorToAdd = .systemOrange
				} else if averageDistance < 20 {
					colorToAdd = .systemGreen.darker(by: 0.5)!
				}

				self.colors.append(colorToAdd)
				self.locations.append(CGFloat(currentPercentage))

				let polyline = MKPolyline(coordinates: Array(toDraw), count: toDraw.count)
				let isLast = currentMaxIndex >= coordinates.count - 1
				canRenderSpeed = isLast

				mapView.removeOverlays(mapView.overlays)
				mapView.addOverlay(polyline, level: .aboveLabels)

				if isLast {
					print("Drawn all \(toDraw.count) = \(currentPercentage)")
					let border = MKPolyline(coordinates: Array(toDraw), count: toDraw.count)
					border.title = "border"
					mapView.insertOverlay(border, below: polyline)
					timer.invalidate()
				}
				currentSegment += 1
			}
			newRenderNeeded = false
		}
	}

	func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		guard let polyline = overlay as? MKPolyline else {
			return MKOverlayRenderer()
		}

		if polyline.title != "border" {
			let renderer = MKPolylineRenderer(polyline: polyline)
			renderer.lineWidth = 2
			renderer.strokeColor = UIColor.label.withAlphaComponent(0.5)
			renderer.strokeColor = .systemBlue
			renderer.lineCap = .round
			return renderer
		}

		let gradientRenderer = MKGradientPolylineRenderer(polyline: polyline)
		gradientRenderer.lineWidth = 2.1
		gradientRenderer.lineCap = .round
		gradientRenderer.strokeColor = .systemBlue
		if canRenderSpeed {
			gradientRenderer.alpha = 0.5
			gradientRenderer.setColors(colors, locations: locations)
		}
		return gradientRenderer
	}

}

struct MapView_Previews: PreviewProvider {

	@State static var currentTrip: TripEntity? = TripEntity(context: TripSingleton.shared.viewContext).apply { entity in
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
			CoordinateEntity(context: TripSingleton.shared.viewContext).apply {
				$0.latitude = location.coordinate.latitude.asDecimal
				$0.longitude = location.coordinate.longitude.asDecimal
			}
		}.forEach { coord in
			entity.addToLocations(coord)
		}
	}

	static var previews: some View {
		MapView(currentTrip: $currentTrip)
	}
}
