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
	@FetchRequest(sortDescriptors: []) private var logHistory: FetchedResults<LogEntity>

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
				ForEach(logHistory.map { $0 as LogEntity }.sorted(by: { $0.timestamp > $1.timestamp })) { log in
					VStack(alignment: .leading) {
						Text(log.timestamp.formatted(date: .omitted, time: .standard))
							.font(.footnote)
							.opacity(0.5)
							.foregroundColor(log.type == 0 ? .blue : .red)
						Text(log.message ?? "No message")
					}
				}
			}

			GeometryReader { _ in
				ScrollView {
					ForEach(previousTrips.map { $0 as TripEntity }.sorted(by: { $0.timestamp > $1.timestamp }), id: \.self) { trip in

						TripCard(trip: trip)
							.frame(height: 150)
							.background(.background)
							.overlay(
								RoundedRectangle(cornerRadius: 20)
									.stroke(.black.opacity(0.1), lineWidth: 2)
							)
							.cornerRadius(20)
							.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 5)
					}
				}
				.padding(10)
				.alert(isPresented: $deletionAlert) {
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
}
