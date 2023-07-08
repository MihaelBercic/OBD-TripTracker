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
	@State var cardIndex: Int = 0

	@GestureState var isDragging = false

	init() {
		UITabBar.appearance().barTintColor = .systemBackground
		UITabBar.appearance().backgroundImage = UIImage()
		UITabBar.appearance().shadowImage = UIImage()
		UITabBar.appearance().backgroundColor = .systemBackground
	}

	@State var isPresented = true
	@State var isLogSheetPresented = false

	var body: some View {
		GeometryReader { screenGeometry in
			ZStack(alignment: .topTrailing) {
				TripMapView(route: $path)
					.ignoresSafeArea()

				VStack(alignment: .center, spacing: 10) {
					Button {} label: {
						Image(systemName: "gear")
							.symbolRenderingMode(SymbolRenderingMode.hierarchical)
							.foregroundStyle(.foreground)
					}
					Divider()
						.frame(width: 35)
						.background(.foreground.opacity(0.6))
					Button {} label: {
						Image(systemName: "info")
							.symbolRenderingMode(SymbolRenderingMode.hierarchical)
							.foregroundStyle(.foreground)
					}
					Divider()
						.frame(width: 35)
						.background(.foreground.opacity(0.6))
					Button {
						isLogSheetPresented = true
					} label: {
						Image(systemName: "list.bullet")
							.symbolRenderingMode(SymbolRenderingMode.hierarchical)
							.foregroundStyle(.foreground)
					}
				}
				.padding([.top, .bottom], 10)
				.background(.thickMaterial)
				.cornerRadius(5)
				.offset(x: -10, y: screenGeometry.safeAreaInsets.top - 30)
				.shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
			}
			.sheet(isPresented: $isPresented) {
				GeometryReader { containerReader in
					VStack(alignment: .leading) {
						let screenCenter = containerReader.size.width / 2
						let colors: [String] = [
							"7C72FF", "8F73FF", "A673FF", "F88C9C", "F7A68B", "F7C18B", "F7D98B", "FFBA7D", "FFA454", "FF7E46",
						]
						let trips: [TripEntity] = previousTrips
							.sorted(by: { $0.timestamp > $1.timestamp })
							.chunked(into: 10).first ?? []
						ScrollView(.horizontal, showsIndicators: false) {
							ScrollViewReader { proxy in
								HStack(spacing: 20) {
									ForEach(trips.indices, id: \.self) { id in
										let trip = trips[id]
										let backgroundColor = Color(UIColor(hex: colors[id]))

										GeometryReader { geometry in
											let midX = geometry.frame(in: .named("container")).midX
											let distanceFromCenter = abs(screenCenter - midX)
											let opacity = max(1.0 - distanceFromCenter / 500, 0.1)
											TripCard(tripEntity: trip)
												.id("\(id)")
												.frame(maxWidth: .infinity, maxHeight: containerReader.size.height)
												.padding(10)
												.background(backgroundColor)
												.opacity(opacity)
												.cornerRadius(10)
												.rotation3DEffect(
													Angle(degrees:
														Double(geometry.frame(in: .global).maxX - 1.4 * geometry.size.width) / -20.0
													),
													axis: (x: 0, y: 1, z: 0)
												)
												.shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 5)
												.foregroundColor(.white)
												.onAppear {
													if id == 0 {
														path = trip.locations.map {
															CLLocation(latitude: $0.latitude.doubleValue, longitude: $0.longitude.doubleValue)
														}
													}
												}
										}
										.frame(width: containerReader.size.width * 0.6, height: 100)
									}
								}
								.padding([.leading, .trailing], 60)
								.frame(height: 120)
								.simultaneousGesture(DragGesture(minimumDistance: 0.0).onEnded { value in
									let distance = value.translation.width
									let isLeft = distance < 0
									let toMove = distance == 0 ? 0 : (isLeft ? 1 : -1)
									let nextIndex = max(0, min(cardIndex + toMove, trips.count - 1))
									let trip = trips[nextIndex]
									print("Ended \(nextIndex)")
									cardIndex = nextIndex
									DispatchQueue.main.async {
										withAnimation(.easeInOut(duration: 0.25)) {
											proxy.scrollTo("\(nextIndex)", anchor: .center)
											path = trip.locations.map {
												CLLocation(latitude: $0.latitude.doubleValue, longitude: $0.longitude.doubleValue)
											}
										}
									}
								})
							}
						}
						.scrollDisabled(true)

						Text("Trips")
							.font(.title)
							.fontWeight(.bold)
							.dynamicTypeSize(.xLarge)
						Button("Clear") {
							do {
								let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TripEntity")
								let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
								let context = TripSingleton.shared.viewContext
								try context.execute(deleteRequest)
								try context.save()
							} catch {
								print(error)
							}
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(20)
				}
				.coordinateSpace(name: "container")
				.presentationDetents([.fraction(0.2), .medium])
				.presentationBackground(.ultraThinMaterial)
				.presentationBackgroundInteraction(.enabled(upThrough: .medium))
				.interactiveDismissDisabled(true)
				.sheet(isPresented: $isLogSheetPresented) {
					LogListView(logHistory: logHistory)
						.presentationDetents([.large])
				}
			}
		}
	}
}

struct Previews_ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
