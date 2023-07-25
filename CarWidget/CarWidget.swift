//
//  CarWidget.swift
//  CarWidget
//
//  Created by Mihael Bercic on 10/06/2023.
//

import WidgetKit
import SwiftUI
import Intents

struct SimpleEntry: TimelineEntry {
	
	var date: Date
	
	let car: String
	var fuel: Double
	var range: Double
	var locked: Bool
	var distance: Double
	var problems: Int
	var total: Double

}

let car = SimpleEntry(date: Date.now, car: "XC70", fuel: 84, range: 802, locked: false, distance: 0.3, problems: 0, total: 69483)


struct CarWidgetEntryView: View {
	
	@Environment(\.widgetFamily) var family
	
	var entry: SimpleEntry
    @State var lastTrip: TripEntity? = nil
	
	var body: some View {
		VStack(spacing: 10) {
			HStack(alignment: .top, spacing: 10) {
				Label("Lock status", systemImage: entry.locked ? "lock.fill":"lock.open.trianglebadge.exclamationmark")
					.labelStyle(.iconOnly)
					.symbolRenderingMode(.multicolor)
				Text(entry.car.uppercased()).fontWeight(.bold).fontDesign(.rounded)
				if entry.problems > 0 {
					Label("Problems", systemImage: entry.problems > 0 ? "exclamationmark.circle":"checkmark.circle")
						.symbolRenderingMode(.multicolor)
						.labelStyle(.iconOnly)
				}
			}
			Divider().frame(height: 5)
			switch family {
				case .systemSmall:
					HStack {
						FuelView(fuelLevel: entry.fuel).scaleEffect(0.7)
					}
				case.systemMedium:
                HStack {
                    VStack(alignment: .leading) {
                        Text("RANGE").fontWeight(.bold).fontDesign(.rounded)
                        Text("\(entry.range.formatted())km")
                    }
                    
                    Spacer()
                    FuelView(fuelLevel: entry.fuel).scaleEffect(0.7)
                    Spacer()
                    VStack(alignment:.trailing) {
                        Text("TOTAL").fontWeight(.bold).fontDesign(.rounded)
                        Text("\(entry.total.formatted())km")
                    }
                }
				case .systemLarge:
					Text("Large")
				
				
				default:
					Text("")
			}
		}.padding([.trailing, .leading], 30)

	}
}



struct MyProvider: TimelineProvider {

	typealias Entry = SimpleEntry

	func placeholder(in context: Context) -> Entry {
		return car
	}

	func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
		return completion(car)
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		let timeline = Timeline(entries: [car], policy: .atEnd)
		completion(timeline)
	}
}

struct CarWidget: Widget {
	let kind: String = "CarWidget"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: MyProvider()) { entry in
			CarWidgetEntryView(entry: entry)
		}
		.configurationDisplayName("My Widget")
		.description("This is an example widget.")
	}
}

struct Previews_CarWidget_Previews: PreviewProvider {
	static var previews: some View {
		CarWidgetEntryView(entry: car)
			.previewContext(WidgetPreviewContext(family: .systemSmall))

	}
}
