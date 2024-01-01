//
//  TripListView.swift
//  CarInfo
//
//  Created by Mihael Berčič on 31. 12. 23.
//

import SwiftUI

struct TripListView: View {
    
    @FetchRequest(sortDescriptors: []) private var previousTrips: FetchedResults<TripEntity>
    @FetchRequest(sortDescriptors: []) private var logHistory: FetchedResults<LogEntity>
    
    var dateFormatter: DateFormatter = .init().apply { formatter in
        formatter.dateFormat = "dd/MM/YY"
    }
    
    var body: some View {
        // let trips: [TripEntity] = [TestEntities.shared.tripEntity, TestEntities.shared.tripEntity]  // previousTrips.sorted(by: { $0.timestamp > $1.timestamp })
        let trips: [TripEntity] = previousTrips.sorted(by: { $0.timestamp > $1.timestamp })
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: trips) { trip in
            trip.start.formatted(date: .abbreviated, time: .omitted)
        }
        
        let sortedDates = trips.map { $0.start }
            .sorted()
            .reversed()
            .map {$0.formatted(date: .abbreviated, time: .omitted)}
            .uniqued()
            
        List {
            ForEach(sortedDates, id: \.self) { date in
                let trippies = grouped[date] ?? []
                Section(date) {
                    ForEach(trippies) { trip in
                        NavigationLink {
                            TripDetailView(trip: trip)
                        } label: {
                            TripCardNew(tripEntity: trip)
                        }
                    }
                }
            }
        }
        .refreshable {
            
        }
        .navigationTitle("Trips")
        .toolbar(.automatic)
    }
}

#Preview {
    TripListView()
}

struct TripCardNew: View {
    
    var tripEntity: TripEntity
    var timeFormatter: DateFormatter = .init().apply { formatter in
        formatter.dateFormat = "HH:mm"
    }
    var dateFormatter: DateFormatter = .init().apply { formatter in
        formatter.dateFormat = "dd/MM/YY"
    }
    
    @State var trips: [TripEntity] = []
    
    var body: some View {
        
        HStack {
            VStack(alignment: .leading) {
                Text(timeFormatter.string(from: tripEntity.start))
                    .fontDesign(.rounded)
                    .bold()
                
                Text(tripEntity.startCity)
                    .fontDesign(.rounded)
                    .opacity(0.5)
                    .font(.footnote)
                Text(tripEntity.startCountry)
                    .fontDesign(.rounded)
                    .font(.footnote)
                    .opacity(0.3)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            VStack(alignment: .center) {
                Text("\(tripEntity.distance, specifier: "%.1f")")
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                
                
                Text("km")
                    .fontDesign(.rounded)
                    .font(.footnote)
                    .opacity(0.5)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(timeFormatter.string(from: tripEntity.end))
                    .fontDesign(.rounded)
                    .bold()
                
                Text(tripEntity.endCity)
                    .fontDesign(.rounded)
                    .font(.footnote)
                    .opacity(0.5)
                Text(tripEntity.endCountry)
                    .fontDesign(.rounded)
                    .font(.footnote)
                    .opacity(0.3)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
    }
    
}
