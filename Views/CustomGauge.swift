//
//  CustomGauge.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import SwiftUI

struct CustomGauge<Data: View>: View {
	var label: String = "sss"
	var iconName: String = ""
	var dataPosition: Alignment = .top
	var data: () -> Data = { EmptyView() as! Data }

	var body: some View {
		let informationIndicator = (!iconName.isEmpty ? AnyView(Label(iconName, systemImage: iconName).labelStyle(.iconOnly)) : AnyView(Text(label)))
			.font(.subheadline)
			.fontWeight(.light)

		switch dataPosition {
		case .top, .bottom:
			VStack(alignment: .center, spacing: 5) {
				if dataPosition == .top {
					data()
					informationIndicator
				} else {
					informationIndicator
					data()
				}
			}
		case .leading, .trailing, _:
			HStack(alignment: .center, spacing: 5) {
				if dataPosition == .leading {
					data()
					informationIndicator
				} else {
					informationIndicator
					data()
				}
			}
		}
	}
}

struct CustomGauge_Previews: PreviewProvider {
	static var previews: some View {
		CustomGauge {
			EmptyView()
		}
	}
}
