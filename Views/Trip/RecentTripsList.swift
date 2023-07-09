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
		GeometryReader { containerReader in
			let screenWidth = containerReader.size.width

			VStack(alignment: .leading) {
				Text("Recent trips")
					.font(.caption)
					.fontWeight(.semibold)

				ScrollView(.horizontal, showsIndicators: false) {
					ScrollViewReader { proxy in
						HStack(spacing: 20) {
							ForEach(trips.indices, id: \.self) { id in
								let trip = trips[id]
								let backgroundColor = Color(UIColor(hex: colors[id]))

								TripCard(tripEntity: trip)
									.id("\(id)")
									.padding(10)
									.frame(width: screenWidth * 0.8)
									.background(backgroundColor)
									.cornerRadius(10)
									.shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 5)
									.foregroundColor(.white)
							}
						}
						.padding([.leading, .trailing], 60)
						.simultaneousGesture(DragGesture(minimumDistance: 0.0).onEnded { value in
							let distance = value.translation.width
							let isLeft = distance < 0
							let toMove = distance == 0 ? 0 : (isLeft ? 1 : -1)
							let nextIndex = max(0, min(tripIndex + toMove, trips.count - 1))
							let trip = trips[nextIndex]
							tripIndex = nextIndex
							currentTrip = trip

							withAnimation(.easeInOut(duration: 0.25)) {
								proxy.scrollTo("\(tripIndex)", anchor: .center)
							}

						})
					}
				}
				.scrollDisabled(true)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(20)
		}
		.coordinateSpace(name: "container")
	}
}

struct RecentTripsList_Previews: PreviewProvider {
	@State static var entity: TripEntity? = TripEntity(context: TripSingleton.shared.viewContext).apply {
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
		RecentTripsList(trips: [], currentTrip: $entity)
	}
}
