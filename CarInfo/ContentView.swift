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
import SwiftUI
import WidgetKit

private var bluetoothManager = BluetoothManager()

struct ContentView: View {
	@State var dict: [UInt8: Measurement] = [:]
	@State var activity: Activity<CarWidgetAttributes>? = nil
	@State private var selection: String = "blue"

	var body: some View {
		VStack {
			Button("Start") {
				let attributes = CarWidgetAttributes(start: Date())
				var initialTrip = Trip()
				let state = CarWidgetAttributes.ContentState(trip: initialTrip)
				activity = try? Activity.request(attributes: attributes, contentState: state, pushType: nil)
			}

			Button("Stop") {
				Task {
					await activity?.end(dismissalPolicy: .immediate)
				}
			}
		}
	}
}
