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

	/// @Environment(\.managedObjectContext) private var viewContext: NSManagedObjectContext
	@FetchRequest(sortDescriptors: []) private var previousTrips: FetchedResults<TripEntity>
	@FetchRequest(sortDescriptors: []) private var logHistory: FetchedResults<LogEntity>

	@State private var currentTrip: TripEntity? = nil

	@State private var currentSheetSize: PresentationDetent = .height(150)
	@State private var offset: Double = 150.0

	@State var selectedView: String = "trip"
	@State var cardIndex: Int = 0

	@State var isPresented = true
	@State var isLogSheetPresented = false
	@State var off = 0.0

	var body: some View {
		let trips: [TripEntity] = previousTrips
			.sorted(by: { $0.timestamp > $1.timestamp })
			.chunked(into: 10).first ?? []

		ZStack(alignment: .bottomLeading) {
			MapView(currentTrip: $currentTrip)
				.ignoresSafeArea()

			VStack(alignment: .leading) {
				HStack {
					Spacer()
					MapToolbar(isLogSheetPresented: $isLogSheetPresented)
						.background(.ultraThickMaterial)
						.cornerRadius(10)
						.shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
				}
				Spacer()

				TripGridView(currentTrip: $currentTrip)
					.offset(y: -off)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding(10)
		}
		.sheet(isPresented: $isPresented) {
			GeometryReader { containerReader in
				VStack(alignment: .leading) {
					RecentTripsList(trips: trips, currentTrip: $currentTrip)
						.frame(height: 130)
				}
				.padding(10)
				.preference(key: InnerHeightPreferenceKey.self, value: containerReader.size.height)
				.onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
					withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
						off = newHeight
					}
				}
			}
			.presentationDetents([.height(150), .medium], selection: $currentSheetSize)
			.presentationDragIndicator(.visible)
			.presentationBackgroundInteraction(.enabled)
			.interactiveDismissDisabled()
			.sheet(isPresented: $isLogSheetPresented) {
				LogListView(logHistory: logHistory)
					.presentationDetents([.large])
			}
		}
	}
}

struct InnerHeightPreferenceKey: PreferenceKey {

	static var defaultValue: Double = .zero
	static func reduce(value: inout Double, nextValue: () -> Double) {
		value = nextValue()
	}

}

struct Previews_ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
