//
//  TripCard.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import MapKit
import SwiftUI

struct TripCard: View {

	let tripEntity: TripEntity

	let formatter: DateComponentsFormatter = DateComponentsFormatter().apply { formatter in
		formatter.unitsStyle = .abbreviated
		formatter.zeroFormattingBehavior = .dropAll
		formatter.allowedUnits = [.hour, .minute, .second]
	}

	let decimalFormatter = NumberFormatter().apply { formatter in
		formatter.maximumFractionDigits = 1
		formatter.minimumFractionDigits = 1
	}

	init(tripEntity: TripEntity) {
		self.tripEntity = tripEntity
	}

	var body: some View {
		VStack {
			Text((tripEntity.start).formatted(date: .numeric, time: .shortened))
				.font(.footnote)
				.fontWeight(.semibold)
				.opacity(0.5)

			HStack(alignment: .center) {
				VStack(alignment: .leading) {
					Text("Ljubljana")
						.font(.body)
						.fontWeight(.semibold)
						.dynamicTypeSize(.small)
						.fontDesign(.rounded)
					Text("SLOVENIA")
						.font(.footnote)
						.fontWeight(.semibold)
						.controlSize(.small)
						.fontDesign(.rounded)
						.dynamicTypeSize(.xSmall)
						.opacity(0.5)
				}
				Spacer()
				Image(systemName: "arrow.right")
				Spacer()
				VStack(alignment: .trailing) {
					Text("Portorož")
						.font(.body)
						.fontWeight(.semibold)
						.dynamicTypeSize(.small)
						.fontDesign(.rounded)
					Text("SLOVENIA")
						.font(.footnote)
						.fontWeight(.semibold)
						.controlSize(.small)
						.fontDesign(.rounded)
						.dynamicTypeSize(.xSmall)
						.opacity(0.5)
				}
			}
			Spacer()
			GeometryReader { reader in
				let width = reader.size.width
				HStack {
					Text("\(decimalFormatter.string(for: tripEntity.distance) ?? "??")km")
						.font(.footnote)
						.opacity(0.8)
					Divider()
						.gridCellUnsizedAxes(.vertical)
					Text(formatter.string(from: tripEntity.start.distance(to: tripEntity.end)) ?? "").font(.footnote)
						.opacity(0.8)
				}
				.frame(maxWidth: .infinity, alignment: .center)
			}
		}
	}

}

struct TripCard_Previews: PreviewProvider {

	static let tripEntity = TripEntity(context: TripSingleton.shared.viewContext).apply {
		$0.start = .now - 3600
	}

	static var previews: some View {
		let _ = print(tripEntity)
		TripCard(tripEntity: tripEntity)
			.previewLayout(.fixed(width: 200, height: 100))
	}
}

struct TripMapView: View {

	var route: Binding<[CLLocation]>
	var routePolyline: MKPolyline? = nil

	var body: some View {
		let coordinates = route.wrappedValue
		let coordinatesCount = coordinates.count
		if coordinatesCount < 5 {
			return MapView(route: MKPolyline(coordinates: [], count: 0))
		}
		let middleElementIndex = coordinatesCount / 2
		let centerCoordinate = coordinates[max(0, middleElementIndex - 1)]
		let span = MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
		let routePolyline = MKPolyline(coordinates: coordinates.map { $0.coordinate }, count: route.count)
		let _ = print(coordinates.count)
		return MapView(route: routePolyline)
	}
}

struct MapView: UIViewRepresentable {

	var route: MKPolyline?
	let mapViewDelegate = MapViewDelegate()

	init(route: MKPolyline) {
		self.route = route
		print("Initialised view!")
	}

	func makeUIView(context _: Context) -> MKMapView {
		let view = MKMapView(frame: .zero)
		view.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)
		addRoute(to: view)
		print("ADding route!")
		return view
	}

	func updateUIView(_ view: MKMapView, context _: Context) {
		view.delegate = mapViewDelegate
		view.removeAnnotations(view.annotations)
		view.isUserInteractionEnabled = false
		view.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: []))
		print("Updating view!")
		addRoute(to: view)

		// view.translatesAutoresizingMaskIntoConstraints = false // (2) In the absence of this, we get constraints error on rotation; and again, it seems one should do this in makeUIView, but has to be here
	}
}

extension MapView {

	func addRoute(to view: MKMapView) {
		print("Add route! \(route == nil)")
		if !view.overlays.isEmpty {
			view.removeOverlays(view.overlays)
		}
		guard let route = route else { return }
		let mapRect = route.boundingMapRect
		view.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: true)
		view.addOverlay(route, level: .aboveLabels)
		print("Adding route!")
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
