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

	@State private var currentSheetSize: PresentationDetent = .height(250)

	@State var selectedView: String = "trip"
	@State var cardIndex: Int = 0

	@State var isPresented = true
	@State var isLogSheetPresented = false
	@State var off = 0.0

	var body: some View {
		let trips: [TripEntity] = previousTrips
			.sorted(by: { $0.timestamp > $1.timestamp })

		ZStack(alignment: .bottomLeading) {
			MapView(currentTrip: $currentTrip)
				.ignoresSafeArea()

			VStack(alignment: .leading) {
				TripGridView(currentTrip: $currentTrip)
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding(10)
		}
		.sheet(isPresented: $isPresented) {
			VStack(alignment: .leading) {
				HStack {
					Text("Trips")
						.font(.title)
						.fontWeight(.bold)
						.fontDesign(.rounded)
					Spacer()
					MapToolbar(isLogSheetPresented: $isLogSheetPresented)
						.background(.foreground.opacity(0.01))
						.cornerRadius(5)
				}
				.padding([.top, .bottom], 10)

				RecentTripsList(trips: trips, currentTrip: $currentTrip)
					.ignoresSafeArea()
			}.onChange(of: currentTrip, perform: { _ in
				currentSheetSize = .height(250)
			})
			.padding([.leading, .trailing], 20)
			.presentationBackground(.ultraThickMaterial)
			.presentationDetents([.height(250), .fraction(0.1), .medium], selection: $currentSheetSize)
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
