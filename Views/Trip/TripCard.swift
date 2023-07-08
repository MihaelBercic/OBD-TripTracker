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
					Text(tripEntity.startCity)
						.font(.body)
						.fontWeight(.semibold)
						.dynamicTypeSize(.small)
						.fontDesign(.rounded)
					Text(tripEntity.startCountry)
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
					Text(tripEntity.endCity)
						.font(.body)
						.fontWeight(.semibold)
						.dynamicTypeSize(.small)
						.fontDesign(.rounded)
					Text(tripEntity.endCountry)
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

	public static let tripEntity = TripEntity(context: TripSingleton.shared.viewContext).apply {
		$0.start = .now - 3600
	}

	static var previews: some View {
		let _ = print(tripEntity)
		TripCard(tripEntity: tripEntity)
			.previewLayout(.fixed(width: 200, height: 100))
	}
}

struct TripMapView: View {

	@Binding var route: [CLLocation]
	@State var routePolyline: MKPolyline = .init()
	@State var chunk = 0

	var body: some View {
		let coordinates = $route.wrappedValue
		let coordinatesCount = coordinates.count
		if coordinatesCount < 5 {
			return MapView(route: MKPolyline(coordinates: [], count: 0))
		}
		let middleElementIndex = coordinatesCount / 2
		let mappedCoordinates = coordinates.map { $0.coordinate }
		let chunks = mappedCoordinates.chunked(into: 10)
		_ = coordinates[max(0, middleElementIndex - 1)]
		_ = MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
//		Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
//			if chunk > chunks.count - 1 {
//				chunk = 0
//				timer.invalidate()
//				print("Invalidating the timer yo...")
//				return
//			}
//			let combined = chunks[0 ... chunk].flatMap { $0 }
//			routePolyline = MKPolyline(coordinates: combined, count: combined.count)
//			print("\(chunk) ... \(chunks.count) ... \(combined.count)")
//			chunk += 1
//		}
		return MapView(route: MKPolyline(coordinates: mappedCoordinates, count: mappedCoordinates.count))
	}
}

struct MapView: UIViewRepresentable {

	var route: MKPolyline
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
		view.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: []))
		print("Updating view!")
		addRoute(to: view)

		// view.translatesAutoresizingMaskIntoConstraints = false // (2) In the absence of this, we get constraints error on rotation; and again, it seems one should do this in makeUIView, but has to be here
	}
}

extension MapView {

	func addRoute(to view: MKMapView) {
		if !view.overlays.isEmpty {
			view.removeOverlays(view.overlays)
		}
		let mapRect = route.boundingMapRect

		view.setVisibleMapRect(mapRect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
		view.addOverlay(route, level: .aboveLabels)
	}

}

class MapViewDelegate: NSObject, MKMapViewDelegate {

	var width: Double = 1.0

	func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
		width = max(3.0, min(4, mapView.visibleMapRect.width / 500))
	}

	func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKGradientPolylineRenderer(overlay: overlay)
		renderer.lineWidth = width
		renderer.strokeColor = UIColor(named: "RouteColor")
		renderer.fillColor = .systemRed
		return renderer
	}
}
