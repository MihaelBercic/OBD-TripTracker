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

	@State var path: [CLLocation] = []
//		CLLocation(latitude: 46.02550, longitude: 14.54126),
//		CLLocation(latitude: 46.02531, longitude: 14.54096),
//		CLLocation(latitude: 46.02504, longitude: 14.54070),
//		CLLocation(latitude: 46.02489, longitude: 14.54038),
//		CLLocation(latitude: 46.02467, longitude: 14.54008),
//		CLLocation(latitude: 46.02450, longitude: 14.53948),
//	]

	@State private var tripInQuestion: TripEntity? = nil

	@EnvironmentObject private var manager: TripDataManager
	@Environment(\.managedObjectContext) private var viewContext: NSManagedObjectContext

	@FetchRequest(sortDescriptors: []) private var previousTrips: FetchedResults<TripEntity>
	@FetchRequest(sortDescriptors: []) private var logHistory: FetchedResults<LogEntity>

	@State private var deletionAlert: Bool = false
	@State var dict: [UInt8: Measurement] = [:]
	@State private var selection: String = "blue"
	@State var region = MKCoordinateRegion(center: CLLocation(latitude: 46.02652652, longitude: 14.54156769).coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

	@State var selectedView: String = "trip"

	@GestureState var isDragging = false

	init() {
		UITabBar.appearance().barTintColor = .systemBackground
		UITabBar.appearance().backgroundImage = UIImage()
		UITabBar.appearance().shadowImage = UIImage()
		UITabBar.appearance().backgroundColor = .systemBackground
	}

	var body: some View {
		TabView {
			VStack(alignment: .leading, spacing: 10) {
				Picker("TITLE", selection: $selectedView) {
					Text("Trip").tag("trip")
					Text("Today").tag("today")
					Text("Week").tag("week")
					Text("Month").tag("month")
					Text("All").tag("all")
				}
				.pickerStyle(.segmented)
				.padding([.leading, .trailing, .top], 30)
				StatisticsView()
					.frame(maxHeight: 140)
					.padding(20)
					.background(.foreground.opacity(0.05))
					.cornerRadius(20)
					.overlay(
						RoundedRectangle(cornerRadius: 20)
							.stroke(.foreground.opacity(0.05), lineWidth: 1)
					)

				TripMapView(route: $path)
					.cornerRadius(5)

				Text("Recent trips")
					.font(.title)
					.fontWeight(.bold)
					.fontDesign(.rounded)

				GeometryReader { containerReader in
					let screenCenter = containerReader.size.width / 2
					let colors: [String] = [
						"7C72FF", "8F73FF", "A673FF", "F88C9C", "F7A68B", "F7C18B", "F7D98B", "FFBA7D", "FFA454", "FF7E46",
					]
					ScrollView(.horizontal, showsIndicators: false) {
						ScrollViewReader { proxy in
							HStack(spacing: 20) {
								let trips: [TripEntity] = previousTrips
									.filter { $0.distance > 0.5 }
									.sorted(by: { $0.timestamp > $1.timestamp })
									.chunked(into: 10)[0]

								ForEach(trips.indices, id: \.self) { id in
									let trip = trips[id]
									let backgroundColor = Color(UIColor(hex: colors[id]))

									GeometryReader { geometry in
										let midX = geometry.frame(in: .named("container")).midX
										let distanceFromCenter = abs(screenCenter - midX)
										let opacity = max(1.0 - distanceFromCenter / 500, 0.1)
										if distanceFromCenter < 20 {
											let _ = DispatchQueue.main.async {
												proxy.scrollTo("\(id)", anchor: .center)
												path = trip.locations.map {
													CLLocation(latitude: $0.latitude.doubleValue, longitude: $0.longitude.doubleValue)
												}
											}
										}
										TripCard(tripEntity: trip)
											.id("\(id)")
											.frame(maxWidth: .infinity, maxHeight: .infinity)
											.padding(10)
											.background(backgroundColor)
											.cornerRadius(10)
											.rotation3DEffect(
												Angle(degrees:
													Double(geometry.frame(in: .global).maxX - 1.5 * geometry.size.width) / -20.0
												),
												axis: (x: 0, y: 1, z: 0)
											)
											.shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 5)
											.foregroundColor(.white)
									}
									.frame(width: 200, height: 100)
								}
							}
							.padding(20)
							.padding([.leading, .trailing], 60)
						}
					}
				}
				.frame(height: 140)
				.coordinateSpace(name: "container")
			}
			.padding(25)
			.tabItem {
				Label("Trips", systemImage: "car.rear.road.lane.dashed")
			}

			VStack {
				Button("Clear") {
					do {
						let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LogEntity")
						let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
						let context = TripSingleton.shared.viewContext
						try context.execute(deleteRequest)
						try context.save()
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
						}.listRowInsets(.none)
					}
				}
				.scrollIndicators(.hidden)
				.listStyle(.plain)
			}
			.badge(logHistory.count)
			.tabItem {
				Label("Logs", systemImage: "list.bullet.rectangle.portrait.fill")
			}

			.navigationBarHidden(true)
		}
	}
}

struct Previews_ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
