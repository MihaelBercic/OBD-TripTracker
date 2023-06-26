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
	@StateObject var measurements = MeasurementsDictionary()

	var body: some View {
		VStack {
			Text("Dict size: \(measurements.measurements.count)")
			Button("Start") {
				let attributes = CarWidgetAttributes(start: Date())
				var initialTrip = Trip()
				let state = CarWidgetAttributes.ContentState(trip: initialTrip)
				activity = try? Activity.request(attributes: attributes, contentState: state, pushType: nil)
				measurements.activity = activity
			}

			Button("Stop") {
				Task {
					await activity?.end(dismissalPolicy: .immediate)
				}
			}

			ForEach(Array(measurements.measurements.keys), id: \.self) { key in
				let measurement = measurements.measurements[key] ?? Measurement(value: 0, unit: Unit(symbol: " ?? "))

				Text("\(String(format: "%.2f", measurement.value)) \(measurement.unit.symbol)")
			}

		}.onAppear {
			Task {
				bluetoothManager.setup(measurements)
			}
		}
	}
}
