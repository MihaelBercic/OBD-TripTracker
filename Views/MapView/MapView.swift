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
		mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
		mapView.showsCompass = false
		mapView.showsScale = true
		// mapView.isPitchEnabled = false
		return mapView
	}

}

class MapViewDelegate: NSObject, MKMapViewDelegate {

	private(set) var currentTrip: TripEntity? = nil
	private(set) var mapView: MKMapView? = nil

	private var path: [CLLocation] = []
	private var colors: [UIColor] = []
	private var locations: [CGFloat] = []

	private var animationTimer: Timer? = nil
	private var newRenderNeeded: Bool = false
	private var canRender: Bool = false
	private var currentTimer: Timer? = nil
	private var currentSegment = 1
	private var canRenderSpeed: Bool = false

	private var totalPolyline: MKPolyline? = nil
	private var previousPolyline: MKPolyline? = nil
	private var currentColor: UIColor = .black
	private var renderers: [MyRenderer] = []

	func setCurrentTrip(mapView: MKMapView, _ newTrip: TripEntity) {
		newRenderNeeded = currentTrip != newTrip
		currentTrip = newTrip
		self.mapView = mapView

		if newRenderNeeded {
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
		let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
		totalPolyline = polyline
		mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50.0, left: 50.0, bottom: 500.0, right: 50.0), animated: true)
	}

	func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
		currentScale = .zero
		guard let totalPolyline = totalPolyline else { return }
		let scale = totalPolyline.boundingMapRect.width / mapView.visibleMapRect.width * minZoomScale
		let decidedScale = min(maxZoomScale, max(minZoomScale, scale))
		renderers.forEach { renderer in
			renderer.scale = decidedScale
			renderer.setNeedsDisplay()
		}
	}

	func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
		if newRenderNeeded {
			renderers = []
			currentSegment = 1
			canRenderSpeed = false
			previousPolyline = nil
			colors = []
			locations = []
			mapView.removeOverlays(mapView.overlays)

			let coordinates = path.map { $0.coordinate }
			let segmentSize = max(1, coordinates.count / 25)

			currentTimer?.invalidate()
			currentTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [self] timer in
				let currentMaxIndex = min(coordinates.count - 1, currentSegment * segmentSize)
				let minimumIndex = max(currentMaxIndex - segmentSize - 1, 0)
				let isLastSegment = currentMaxIndex >= coordinates.count - 1
				let segment = Array(path[minimumIndex ... currentMaxIndex])
				let averageSpeed = segment.reduce(0.0) { $0 + $1.speed } / Double(segment.count) * 3.6

				if averageSpeed == 0.0 {
					currentColor = UIColor(named: "RouteStop")!
				} else if averageSpeed <= 15 {
					currentColor = UIColor(named: "RouteSuperSlow")!
				} else if averageSpeed <= 30 {
					currentColor = UIColor(named: "RouteSlow")!
				} else if averageSpeed <= 60 {
					currentColor = UIColor(named: "RouteMedium")!
				} else if averageSpeed <= 90 {
					currentColor = UIColor(named: "RouteFast")!
				} else {
					currentColor = UIColor(named: "RouteSuperFast")!
				}
				let cleanedCoordinates = segment.map { $0.coordinate }
				let polyline = MKPolyline(coordinates: cleanedCoordinates, count: cleanedCoordinates.count)
				let border = MKPolyline(coordinates: cleanedCoordinates, count: cleanedCoordinates.count)

				border.title = "border"
				if let previousPolyline = previousPolyline {
					mapView.insertOverlay(border, below: previousPolyline)
					mapView.insertOverlay(polyline, above: previousPolyline)
				} else {
					mapView.addOverlays([border, polyline], level: .aboveLabels)
				}
				previousPolyline = polyline
				currentSegment += 1
				if isLastSegment {
					resetMemory()
					timer.invalidate()
				}
			}
			newRenderNeeded = false
		}
	}

	private func resetMemory() {
		newRenderNeeded = false
		path = []
	}

	func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		guard let polyline = overlay as? MKPolyline else {
			return MKOverlayRenderer()
		}

		let percentageChange = 15.0
		let isBorder = polyline.title == "border"
		let isLightMode = UIScreen.main.traitCollection.userInterfaceStyle == .light
		let renderer = MyRenderer(polyline: polyline).apply {
			$0.lineWidth = isBorder ? 2.5 : 1.5
			$0.strokeColor = isBorder ? (isLightMode ? currentColor.darker(by: percentageChange) : currentColor.lighter(by: percentageChange)) : currentColor
			$0.lineCap = .round
			// $0.setColors(isBorder ? colors.map { isLightMode ? $0.darker(by: percentageChange)! : $0.lighter(by: percentageChange)! } : colors, locations: locations)
		}
		renderers.append(renderer)
		return renderer
	}

}

let minZoomScale: MKZoomScale = 0.0001
let maxZoomScale: MKZoomScale = 0.1
var currentScale: CGFloat = .zero

class MyRenderer: MKPolylineRenderer {

	var scale: CGFloat? = nil

	override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
		let decidedScale = min(maxZoomScale, max(minZoomScale, zoomScale))
		if decidedScale >= currentScale {
			currentScale = decidedScale
		}
		super.draw(mapRect, zoomScale: currentScale, in: context)
	}
}

struct MapView_Previews: PreviewProvider {

	@State static var currentTrip: TripEntity? = TripEntity(context: CoreDataManager.shared.viewContext).apply { entity in
		entity.start = .now
		entity.end = .now
		entity.timestamp = .now
		[
			CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02550, longitude: 14.54126), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 10.0, timestamp: .now),
			CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02531, longitude: 14.54096), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 30.0, timestamp: .now),
			CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02504, longitude: 14.54070), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 50.0, timestamp: .now),
			CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02489, longitude: 14.54038), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 23.0, timestamp: .now),
			CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02467, longitude: 14.54008), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 100.0, timestamp: .now),
			CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02450, longitude: 14.53948), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 5.0, timestamp: .now),
		].map { location in
			CoordinateEntity(context: CoreDataManager.shared.viewContext).apply {
				$0.latitude = location.coordinate.latitude.asDecimal
				$0.longitude = location.coordinate.longitude.asDecimal
				$0.speed = Int16(location.speed.rounded())
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

extension UIBezierPath {
	private static func midpoint(_ a: CGPoint, b: CGPoint) -> CGPoint {
		CGPoint(
			x: (b.x + a.x) / 2,
			y: (b.y + a.y) / 2
		)
	}

	static func chaikinPath(_ pts: [CGPoint]) -> UIBezierPath? {
		guard pts.count > 2 else {
			return nil
		}

		let path = UIBezierPath()
		for i in 1 ... pts.count {
			let prev = pts[i - 1]
			let cp = pts[i % pts.count]
			let next = pts[(i + 1) % pts.count]

			path.move(
				to: midpoint(prev, b: cp)
			)
			path.addQuadCurve(
				to: midpoint(cp, b: next),
				controlPoint: cp
			)
		}
		path.close()
		return path
	}
}
