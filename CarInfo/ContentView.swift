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
    
    @State private var tripView: PossibleViews = .single
    @State private var currentTrips: [TripEntity] = []

    private enum PossibleViews {
        case single
        case today
        case thisWeek
        case thisMonth
    }
    
	var body: some View {
		let trips: [TripEntity] = previousTrips
			.sorted(by: { $0.timestamp > $1.timestamp })

		ZStack(alignment: .bottomLeading) {
			MapView(currentTrips: $currentTrips)
                .ignoresSafeArea()

			VStack(alignment: .leading) {
                TripGridView(currentTrips: $currentTrips)
                    .background(.black)
                    .cornerRadius(10)
				Spacer()
            }.padding(5)
            
			
		}
		.sheet(isPresented: $isPresented) {
			VStack(alignment: .leading) {
                HStack {
                    Picker("tripViewSelection", selection: $tripView) {
                            Text("Today")
                                .tag(PossibleViews.today)
                            Text("Week")
                                .tag(PossibleViews.thisWeek)
                            Text("Month")
                                .tag(PossibleViews.thisMonth)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                    
                
					Spacer()
					MapToolbar(isLogSheetPresented: $isLogSheetPresented)
						.background(.foreground.opacity(0.01))
						.cornerRadius(5)
				}
				.padding([.top, .bottom], 10)

                RecentTripsList(trips: trips, currentTrips: $currentTrips)
					.ignoresSafeArea()
			}
            .onChange(of: tripView, perform: { selectedTripView in
                currentTrips = trips.filter { trip in
                    let distanceInDays = Calendar.current.dateComponents([.day], from: trip.start, to: .now).day ?? 0
                    switch selectedTripView {
                    case .today: return trip.start.isInToday
                    case .thisWeek: return distanceInDays <= 7
                    case .thisMonth: return distanceInDays <= 31
                    default: return false;
                    }
                }
            })
            .onChange(of: currentTrips, perform: { trips in
                currentSheetSize = .height(250)
                currentTrip = nil
                if trips.count == 1 {
                    tripView = .single
                    currentTrip = trips.first!
                }
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
