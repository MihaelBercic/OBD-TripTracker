//
//  ContentView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 10/06/2023.
//
//

import ActivityKit
import CoreBluetooth
import CoreData
import MapKit

import SwiftUI
import WidgetKit

struct ContentView: View {

	let path = [
		CLLocation(latitude: 46.02550, longitude: 14.54126),
		CLLocation(latitude: 46.02531, longitude: 14.54096),
		CLLocation(latitude: 46.02504, longitude: 14.54070),
		CLLocation(latitude: 46.02489, longitude: 14.54038),
		CLLocation(latitude: 46.02467, longitude: 14.54008),
		CLLocation(latitude: 46.02450, longitude: 14.53948),
	]

	@State private var tripInQuestion: TripEntity? = nil

	@EnvironmentObject private var manager: TripDataManager
	@Environment(\.managedObjectContext) private var viewContext: NSManagedObjectContext

	@FetchRequest(sortDescriptors: []) private var previousTrips: FetchedResults<TripEntity>

	@State private var deletionAlert: Bool = false
	@State var dict: [UInt8: Measurement] = [:]
	@State private var selection: String = "blue"
	@State var region = MKCoordinateRegion(center: CLLocation(latitude: 46.02652652, longitude: 14.54156769).coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

	var body: some View {
		VStack {
			Button("Test") {
				let tripEntity = TripEntity(context: viewContext)
				tripEntity.averageSpeed = 99
				tripEntity.distance = 13.4
				tripEntity.timestamp = .now
				tripEntity.start = .now
				tripEntity.end = .now

				path.forEach { location in
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

			List {
				ForEach(previousTrips.map { $0 as TripEntity }, id: \.self) { trip in

					let route = trip.locations.map { CLLocation(latitude: $0.latitude.doubleValue, longitude: $0.longitude.doubleValue) }

					Group {
						TripMapView(route: route)
							.frame(height: 150)
							.cornerRadius(5)
						Text("Trip locations: \(trip.locations.count)")
						Text("Trip distance: \(String(format: "%.2f", trip.distance))km")
						Button("Delete") {
							tripInQuestion = trip
							deletionAlert = true
						}
					}
				}
			}.alert(isPresented: $deletionAlert) {
				Alert(title: Text("Delete trip?"), primaryButton: .default(Text("Yes")) {
					do {
						guard let trip = tripInQuestion else { return }
						viewContext.delete(trip)
						try viewContext.save()
					} catch {
						print(error)
					}
				}, secondaryButton: .default(Text("No")))
			}
		}
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
		addRoute(to: view)
		return view
	}

	func updateUIView(_ view: MKMapView, context _: Context) {
		view.isUserInteractionEnabled = false
		view.delegate = mapViewDelegate // (1) This should be set in makeUIView, but it is getting reset to `nil`
		view.translatesAutoresizingMaskIntoConstraints = false // (2) In the absence of this, we get constraints error on rotation; and again, it seems one should do this in makeUIView, but has to be here
		view.interactions = []
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
		view.addOverlay(route)
	}
}

class MapViewDelegate: NSObject, MKMapViewDelegate {
	func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKGradientPolylineRenderer(overlay: overlay)
		renderer.lineWidth = 4
		renderer.setColors([.systemBlue, .systemGreen, .systemBlue], locations: [0.3, 0.5, 0.8])
		return renderer
	}
}
