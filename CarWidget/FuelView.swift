//
//  FuelView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 10/06/2023.
//

import SwiftUI

struct FuelView: View {

	var fuelLevel:Double
	private let purpleGradient = Gradient(colors: [.green, .red])
	
    var body: some View {
		Gauge(value: fuelLevel) {
			Label("Fuelpump", systemImage: "fuelpump.fill").labelStyle(.iconOnly)
		} currentValueLabel: {
			Text("\(fuelLevel.formatted())")
		}
		.gaugeStyle(.accessoryCircular)
		
	}
}

struct FuelView_Previews: PreviewProvider {
    static var previews: some View {
		FuelView(fuelLevel: 12.0)
    }
}
