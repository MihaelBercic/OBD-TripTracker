//
//  CarWidgetLiveActivity.swift
//  CarWidget
//
//  Created by Mihael Bercic on 10/06/2023.
//

import ActivityKit
import CoreLocation
import SwiftUI
import WidgetKit

struct CarWidgetAttributes: ActivityAttributes {
	public struct ContentState: Codable, Hashable {
		var trip: Trip
	}
}

struct CarWidgetLiveActivity: Widget {
	var body: some WidgetConfiguration {
		ActivityConfiguration(for: CarWidgetAttributes.self) { context in
			// Lock screen/banner UI goes here
			LiveActivityView(contentState: context.state)
		} dynamicIsland: { _ in
			DynamicIsland {
				// Expanded UI goes here.  Compose the expanded UI through
				// various regions, like leading/trailing/center/bottom
				DynamicIslandExpandedRegion(.leading) {
					Text("Leading")
				}
				DynamicIslandExpandedRegion(.trailing) {
					Text("Trailing")
				}
				DynamicIslandExpandedRegion(.bottom) {
					Text("Bottom")
					// more content
				}
			} compactLeading: {
				Text("L")
			} compactTrailing: {
				Text("T")
			} minimal: {
				Text("Min")
			}
			.widgetURL(URL(string: "http://www.apple.com"))
			.keylineTint(Color.red)
		}
	}
}

struct LiveActivityView: View {

	let contentState: CarWidgetAttributes.ContentState
	let formatter: DateComponentsFormatter = DateComponentsFormatter().apply { formatter in
		formatter.unitsStyle = .abbreviated
		formatter.zeroFormattingBehavior = .dropAll
		formatter.allowedUnits = [.hour, .minute, .second]
	}

	let decimalFormatter = NumberFormatter().apply { formatter in
		formatter.maximumFractionDigits = 1
		formatter.minimumFractionDigits = 1
	}

	init(contentState: CarWidgetAttributes.ContentState) {
		self.contentState = contentState
	}

	var body: some View {
		let trip = contentState.trip
		ZStack {
			Color(.label.withAlphaComponent(0.1))
			ContainerRelativeShape()
				.inset(by: 5)
				.fill(.background.opacity(0.1))
			Grid(alignment: .leading) {
				GridRow(alignment: .center) {
					CustomGauge(iconName: "road.lanes", dataPosition: .bottom) {
						HStack(alignment: .bottom, spacing: 0) {
							Text("\(decimalFormatter.string(for: trip.distance) ?? "-")").fontWeight(.bold)
							Text("km").font(.footnote).foregroundColor(.secondary)
						}
					}.frame(maxWidth: .infinity)
					HStack(alignment: .center) {
						Text("\(formatter.string(from: trip.start.distance(to: Date.now)) ?? "-")")
							.font(.footnote)
							.fontWeight(.bold)
							.fontDesign(.rounded)
					}.frame(maxWidth: .infinity)
					CustomGauge(iconName: "fanblades", dataPosition: .bottom) {
						HStack(alignment: .top, spacing: 0) {
							Text("\(decimalFormatter.string(for: trip.ambientTemperature) ?? "-")").fontWeight(.bold)
							Text("°C").font(.footnote).foregroundColor(.secondary)
						}.fixedSize(horizontal: true, vertical: false)
					}.frame(maxWidth: .infinity).gridColumnAlignment(.trailing)
				}
				Divider().gridCellUnsizedAxes([.horizontal]).overlay(.foreground).cornerRadius(10).opacity(0.2)
				GridRow(alignment: .bottom) {
					CustomGauge(iconName: "speedometer") {
						HStack(alignment: .top, spacing: 0) {
							Text("\(decimalFormatter.string(for: trip.speed) ?? "-")").fontWeight(.bold)
							Text("km/h").font(.footnote).foregroundColor(.secondary)
						}
					}.frame(maxWidth: .infinity)
					CustomGauge(iconName: "fuelpump") {
						HStack(alignment: .top, spacing: 0) {
							Text("\(decimalFormatter.string(for: trip.fuelTankLevel) ?? "-")L").fontWeight(.bold)
							Text("%").font(.footnote).foregroundColor(.secondary)
						}
					}.frame(maxWidth: .infinity)
					CustomGauge(iconName: "engine.combustion") {
						HStack(alignment: .top, spacing: 0) {
							Text("\(decimalFormatter.string(for: trip.engineTemp) ?? "-")").fontWeight(.bold)
							Text("°C").font(.footnote).foregroundColor(.secondary)
						}
					}.frame(maxWidth: .infinity)
				}
			}.padding(15)
		}
	}
}

struct CustomGauge<Data: View>: View {
	var label: String = "sss"
	var iconName: String = ""
	var dataPosition: Alignment = .top
	var data: () -> Data

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

struct Previews_CarWidgetLiveActivity_Previews: PreviewProvider {
	static var previews: some View {
		LiveActivityView(contentState: CarWidgetAttributes.ContentState(trip: Trip()))
			.previewContext(WidgetPreviewContext(family: .systemMedium))
	}
}
