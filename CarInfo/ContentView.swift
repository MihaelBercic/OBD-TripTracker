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

	@State var dict: [UInt8: Measurement] = [:]
	@State private var selection: String = "blue"
	@State var region = MKCoordinateRegion(center: CLLocation(latitude: 46.02652652, longitude: 14.54156769).coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
	var body: some View {
		VStack {
			Map(
				coordinateRegion: $region,
				interactionModes: [],
				showsUserLocation: true
			)
			Button("Start") {}
		}
	}
}
