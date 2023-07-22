//
//  RecentTripsList.swift
//  CarInfo
//
//  Created by Mihael Bercic on 08/07/2023.
//

import SwiftUI

struct RecentTripsList: View {

	let colors: [String] = [
		"7C72FF", "8F73FF", "A673FF", "F88C9C", "F7A68B", "F7C18B", "F7D98B", "FFBA7D", "FFA454", "FF7E46",
	]

	var trips: [TripEntity]
	@State private var tripIndex = 0
	@Binding var currentTrip: TripEntity?

	var body: some View {
		let trippies = trips.chunked(into: 2)
		ScrollView {
			Grid(horizontalSpacing: 10, verticalSpacing: 10) {
				ForEach(trippies.indices, id: \.self) { tripIndex in
					let trips = trippies[tripIndex]
					GridRow {
						ForEach(trips.indices, id: \.self) { tripIndex in
							let trip = trips[tripIndex]
							var tripTime = "morning"
							let dateComponents = Calendar.current.dateComponents([.hour], from: trip.start)
							let time = dateComponents.hour ?? 0
							let _ = { if time >= 22 || time < 5 {
								tripTime = "night"
							} else if time < 10 {
								tripTime = "morning"
							} else if time < 18 {
								tripTime = "day"
							} else if time < 22 {
								tripTime = "evening"
							}}()
							let backgroundColor = Color(UIColor(named: "\(tripTime.capitalized)RideBackground") ?? .yellow)
							let backgroundColorEnd = Color(UIColor(named: "\(tripTime.capitalized)RideBackground")?.lighter(by: 1.6) ?? .yellow)

							TripCard(tripEntity: trip)
								.padding(10)
								.background(LinearGradient(
									colors: [backgroundColor, backgroundColorEnd],
									startPoint: .leading,
									endPoint: .trailing
								))
								.overlay(
									RoundedRectangle(cornerRadius: 10)
										.stroke(.foreground.opacity(0.05), lineWidth: 5)
								)
								.cornerRadius(10)
								.shadow(color: .secondary.opacity(0.05), radius: 5, x: 0, y: 5)
								.foregroundColor(.white)
								.onTapGesture {
									currentTrip = trip
								}
								.contextMenu {
									Button {
										currentTrip = nil
										CoreDataManager.shared.delete(entity: trip)
									} label: {
										Label("Remove", systemImage: "trash")
											.foregroundStyle(.red)
											.symbolRenderingMode(.hierarchical)
									}
								}
						}
					}
				}
			}
		}

		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

struct RecentTripsList_Previews: PreviewProvider {
	@State static var entity: TripEntity? = TripEntity(context: CoreDataManager.shared.viewContext).apply {
		$0.start = .now
		$0.startCity = "Ljubljana"
		$0.startCountry = "Slovenija"
		$0.endCity = "Portorož"
		$0.endCountry = "Slovenija"
		$0.end = .now + 100
		$0.distance = 12.3
		$0.fuelStart = 100.0
		$0.fuelEnd = 90.0
	}

	static var previews: some View {
		let e = entity.unsafelyUnwrapped
		RecentTripsList(trips: [e, e, e, e, e, e], currentTrip: $entity)
	}
}
