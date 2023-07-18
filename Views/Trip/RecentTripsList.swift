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
			let trippies = trips.chunked(into: 2)
			VStack(alignment: .leading) {
				Text("Trips")
					.font(.title)
					.fontWeight(.bold)
					.fontDesign(.rounded)

				ScrollView {
					Grid(horizontalSpacing: 10, verticalSpacing: 10) {
						ForEach(0 ..< trippies.count) { tripieIndex in
							let trips = trippies[tripieIndex]
							GridRow {
								ForEach(0 ..< trips.count) { tripIndex in
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

//				ScrollView(.horizontal, showsIndicators: false) {
//					ScrollViewReader { proxy in
//						HStack(spacing: 20) {
//							ForEach(trips.indices, id: \.self) { id in
//								let trip = trips[id]
//								var tripTime = "morning"
//								let dateComponents = Calendar.current.dateComponents([.hour], from: trip.start)
//								let time = dateComponents.hour ?? 0
//								let _ = { if time >= 22 || time < 5 {
//									tripTime = "night"
//								} else if time < 10 {
//									tripTime = "morning"
//								} else if time < 18 {
//									tripTime = "day"
//								} else if time < 22 {
//									tripTime = "evening"
//								}}()
//								let backgroundColor = Color(UIColor(named: "\(tripTime.capitalized)RideBackground") ?? .yellow)
//								let backgroundColorEnd = Color(UIColor(named: "\(tripTime.capitalized)RideBackground")?.lighter(by: 1.6) ?? .yellow)
//
//								TripCard(tripEntity: trip)
//									.id("\(id)")
//									.padding(10)
//									.frame(width: screenWidth * 0.6)
//									.background(LinearGradient(
//										colors: [backgroundColor, backgroundColorEnd],
//										startPoint: .leading,
//										endPoint: .trailing
//									))
//									.overlay(
//										RoundedRectangle(cornerRadius: 10)
//											.stroke(.foreground.opacity(0.05), lineWidth: 5)
//									)
//									.cornerRadius(10)
//									.shadow(color: .secondary.opacity(0.05), radius: 5, x: 0, y: 5)
//									.foregroundColor(.white)
//									.contextMenu {
//										Button {
//											CoreDataManager.shared.delete(entity: trip)
//										} label: {
//											Label("Remove", systemImage: "trash")
//												.foregroundStyle(.red)
//												.symbolRenderingMode(.hierarchical)
//										}
//									}
//							}
//						}
//						.padding([.top], 10)
//						.padding([.bottom], 20)
//						.padding([.leading, .trailing], 60)
//						.simultaneousGesture(DragGesture(minimumDistance: 0.0).onEnded { value in
//							let distance = value.translation.width
//							let isLeft = distance < 0
//							let toMove = distance == 0 ? 0 : (isLeft ? 1 : -1)
//							let nextIndex = max(0, min(tripIndex + toMove, trips.count - 1))
//							let trip = trips[nextIndex]
//							tripIndex = nextIndex
//							currentTrip = trip
//
//							withAnimation(.easeInOut(duration: 0.25)) {
//								proxy.scrollTo("\(tripIndex)", anchor: .center)
//							}
//
//						})
//					}
//				}
//				.scrollDisabled(true)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.coordinateSpace(name: "container")
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
