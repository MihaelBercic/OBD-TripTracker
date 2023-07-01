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
	var body: some View {
		VStack {
			Button("Start") {}
		}
	}
}
