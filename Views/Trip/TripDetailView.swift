//
//  TripDetailView.swift
//  CarInfo
//
//  Created by Mihael Berčič on 1. 01. 24.
//

import SwiftUI

struct TripDetailView: View {
    
    @State var trip: TripEntity
    @State var trips: [TripEntity] = []
    
    var body: some View {
        VStack {
            MapView(currentTrips: $trips)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onAppear {
                    trips = [trip]
                }
            Spacer()
        }
        .padding(20)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TripDetailView(trip: TestEntities.shared.tripEntity)
}
