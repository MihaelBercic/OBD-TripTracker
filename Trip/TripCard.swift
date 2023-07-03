//
//  TripCard.swift
//  CarInfo
//
//  Created by Mihael Bercic on 02/07/2023.
//

import CoreData
import MapKit
import SwiftUI

struct TripCard: View {

	@State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 34.011_286, longitude: -116.166868), span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0))

	let trip: TripEntity?
	let route: [CLLocation]

	init(trip: TripEntity? = nil) {
		self.trip = trip
		route = trip?.locations.map { CLLocation(latitude: $0.latitude.doubleValue, longitude: $0.longitude.doubleValue) } ?? []
	}

	var body: some View {
		GeometryReader { reader in
			Grid {
				GridRow(alignment: .center) {
					VStack(alignment: .leading) {
						Text("Ljubljana, Slovenija")
							.font(.footnote)
							.fontWeight(.bold)
						Grid(alignment: .leading) {
							GridRow(alignment: .top) {
								VStack(alignment: .leading, spacing: 10) {
									MeasurementView(iconName: "flag.2.crossed.circle", text: "", value: trip?.start.formatted() ?? "X")
									Spacer()
									MeasurementView(iconName: "flag.checkered.circle", text: "", value: trip?.end.formatted() ?? "X")
								}
							}
							.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
						}
						.padding([.leading, .trailing], 10)
						.overlay(
							Rectangle()
								.strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
								.frame(width: 2)
								.foregroundColor(.black.opacity(0.2)), alignment: .leading
						)

						Text("Portorož, Slovenija")
							.font(.footnote)
							.fontWeight(.bold)
					}
					.frame(width: reader.size.width * 0.4, alignment: .leading)
					TripMapView(route: route)
						.overlay(
							RoundedRectangle(cornerRadius: 20)
								.stroke(Color(.systemBlue), lineWidth: 2)
						)
						.cornerRadius(20)
				}
				.padding(15)
			}
		}
	}
}

struct MeasurementView: View {

	let iconName: String
	let text: String
	let value: String

	var body: some View {
		let icon = Image(systemName: iconName) ?? Image(iconName)
		HStack {
			Label {} icon: {
				icon
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(.green, .red)
			}
			Text(value)
				.font(.callout)
		}
	}
}

struct TripCard_Previews: PreviewProvider {

	static let trip = TripEntity().apply {
		$0.averageSpeed = 10
		$0.distance = 12.3
		$0.start = .now - 120
		$0.end = .now
		$0.locations = []
		$0.timestamp = .now
	}

	static var previews: some View {
		return TripCard()
			.frame(height: 150)
			.background(Color(.systemBlue).opacity(0.1))
	}
}

struct TripMapView: View {

	let coordinates: [CLLocation]
	var routePolyline: MKPolyline?
	@State var region: MKCoordinateRegion

	init(route: [CLLocation]) {
		let coordinatesCount = route.count
		let middleElementIndex = coordinatesCount / 2
		let centerCoordinate = route[max(0, middleElementIndex - 1)]
		let span = MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
		region = MKCoordinateRegion(center: centerCoordinate.coordinate, span: span)
		coordinates = route
		routePolyline = MKPolyline(coordinates: coordinates.map { $0.coordinate }, count: route.count)
	}

	var body: some View {
		MapView(route: routePolyline)
	}
}

struct MapView: UIViewRepresentable {

	var route: MKPolyline?
	let mapViewDelegate = MapViewDelegate()

	func makeUIView(context _: Context) -> MKMapView {
		let view = MKMapView(frame: .zero)
		view.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)
		addRoute(to: view)
		return view
	}

	func updateUIView(_ view: MKMapView, context _: Context) {
		view.delegate = mapViewDelegate
		view.removeAnnotations(view.annotations)
		view.isUserInteractionEnabled = false
		view.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: []))

		// view.translatesAutoresizingMaskIntoConstraints = false // (2) In the absence of this, we get constraints error on rotation; and again, it seems one should do this in makeUIView, but has to be here
	}
}

private extension MapView {

	func addRoute(to view: MKMapView) {
		if !view.overlays.isEmpty {
			view.removeOverlays(view.overlays)
		}
		guard let route = route else { return }
		let mapRect = route.boundingMapRect
		view.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: true)
		view.addOverlay(route, level: .aboveLabels)
	}
}

class MapViewDelegate: NSObject, MKMapViewDelegate {

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKGradientPolylineRenderer(overlay: overlay)
		let width = max(1.0, min(1.5, mapView.visibleMapRect.width / 1000))
		renderer.lineWidth = width
		renderer.strokeColor = .blue
		renderer.fillColor = .systemRed
		return renderer
	}

}
