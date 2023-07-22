//
//  TripGridView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 08/07/2023.
//

import SwiftUI

struct TripGridView: View {

	@Binding var currentTrip: TripEntity?
	private let backgroundColor: UIColor = .systemBackground.darker(by: 0.8)!
	private let foregroundColor: UIColor = .label

	private let formatter: DateComponentsFormatter = DateComponentsFormatter().apply { formatter in
		formatter.unitsStyle = .abbreviated
		formatter.zeroFormattingBehavior = .dropAll
		formatter.allowedUnits = [.hour, .minute, .second]
	}

	private let dateFormatter = DateFormatter().apply { formatter in
		formatter.dateStyle = .short
		formatter.timeStyle = .none
		formatter.setLocalizedDateFormatFromTemplate("ddMM")
	}

	var body: some View {
		guard let currentTrip = currentTrip else { return AnyView(EmptyView()) }
		return AnyView(
			Grid(horizontalSpacing: 5, verticalSpacing: 5) {
				let startDate = currentTrip.start
				let endDate = currentTrip.end
				let driveDuration = startDate.distance(to: endDate)
				let averageSpeed = (currentTrip.distance * 1000 / driveDuration.magnitude) * 3.6

				GridRow {
					HStack(alignment: .center) {
						VStack(alignment: .leading) {
							Text(currentTrip.startCity)
								.font(.body)
								.fontWeight(.semibold)
								.dynamicTypeSize(.small)
								.fontDesign(.rounded)
							Text(currentTrip.startCountry)
								.font(.footnote)
								.fontWeight(.semibold)
								.controlSize(.small)
								.fontDesign(.rounded)
								.dynamicTypeSize(.xSmall)
								.opacity(0.5)
							HStack {
								Text(startDate.formatted(date: .omitted, time: Date.FormatStyle.TimeStyle.shortened))
									.font(.footnote)
									.fontDesign(.rounded)
									.fontWeight(.semibold)
									.foregroundColor(.green)
								Text(dateFormatter.string(from: startDate))
									.font(.footnote)
									.fontWeight(.semibold)
									.controlSize(.small)
									.fontDesign(.rounded)
									.dynamicTypeSize(.xSmall)
									.opacity(0.5)
							}
						}
						Spacer()
						Image(systemName: "arrow.right.circle")
							.symbolRenderingMode(.hierarchical)
							.foregroundStyle(.green)
						Spacer()
						VStack(spacing: 5) {
							HStack(alignment: .bottom, spacing: 3) {
								Text(String(format: "%.0f", currentTrip.distance))
									.fontDesign(.rounded)
									.font(.footnote)
								Text("km")
									.font(.caption2)
									.opacity(0.7)
									.foregroundStyle(
										LinearGradient(
											colors: [.teal, .green],
											startPoint: .leading,
											endPoint: .trailing
										)
									)
									.fontWeight(.semibold)
							}
							Text(formatter.string(from: startDate.distance(to: endDate)) ?? "0h 0m 0s")
								.fontDesign(.rounded)
								.font(.footnote)
						}
						Spacer()
						Image(systemName: "arrow.right.circle")
							.symbolRenderingMode(.hierarchical)
							.foregroundStyle(.blue)
						Spacer()
						VStack(alignment: .trailing) {
							Text(currentTrip.endCity)
								.font(.body)
								.fontWeight(.semibold)
								.dynamicTypeSize(.small)
								.fontDesign(.rounded)
							Text(currentTrip.endCountry)
								.font(.footnote)
								.fontWeight(.semibold)
								.controlSize(.small)
								.fontDesign(.rounded)
								.dynamicTypeSize(.xSmall)
								.opacity(0.5)
							HStack {
								Text(endDate.formatted(date: .omitted, time: Date.FormatStyle.TimeStyle.shortened))
									.font(.footnote)
									.fontDesign(.rounded)
									.fontWeight(.semibold)
									.foregroundColor(.blue)
								Text(dateFormatter.string(from: endDate))
									.font(.footnote)
									.fontWeight(.semibold)
									.controlSize(.small)
									.fontDesign(.rounded)
									.dynamicTypeSize(.xSmall)
									.opacity(0.5)
							}
						}
					}
					.frame(maxWidth: .infinity)
					.gridCellColumns(3)
				}
				.padding(10)
				.padding([.leading, .trailing], 10)
				.foregroundColor(Color(foregroundColor))
				.background(.ultraThinMaterial)
				.cornerRadius(5)
				.shadow(radius: 1)

				GridRow {
					VStack(alignment: .leading) {
						Text("Fuel used")
							.font(.caption)
							.opacity(0.8)
						HStack(alignment: .bottom, spacing: 5) {
							let fuelStart = currentTrip.fuelStart.doubleValue
							let fuelEnd = currentTrip.fuelEnd.doubleValue
							let fuelUsed = (fuelStart - fuelEnd) * 0.70
							Text(String(format: "%.1f", abs(fuelUsed)))
								.fontDesign(.rounded)
								.fontWeight(.semibold)
							Text("L")
								.font(.caption)
								.opacity(0.7)
								.foregroundStyle(
									LinearGradient(
										colors: [.pink, .red],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.fontWeight(.semibold)
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)

					VStack(alignment: .leading) {
						Text("Avg. speed")
							.font(.caption)
							.opacity(0.8)
						HStack(alignment: .bottom, spacing: 5) {
							Text(String(format: "%.0f", averageSpeed))
								.fontDesign(.rounded)
								.fontWeight(.semibold)
							Text("km/h")
								.font(.caption2)
								.opacity(0.7)
								.foregroundStyle(
									LinearGradient(
										colors: [.red, .orange],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.fontWeight(.semibold)
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)

					VStack(alignment: .center) {
						Text("Trip score")
							.font(.caption)
							.fontWeight(.semibold)
							.opacity(1)
						HStack(alignment: .bottom, spacing: 5) {
							Text("7.8")
								.fontDesign(.rounded)
								.fontWeight(.bold)
								.foregroundStyle(
									LinearGradient(
										colors: [.teal, .green],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.fontWeight(.semibold)
						}.frame(maxWidth: .infinity)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
				}
				.padding(10)
				.padding([.leading, .trailing], 10)
				.background(.ultraThinMaterial)
				.foregroundColor(Color(foregroundColor))
				.cornerRadius(5)
				.shadow(radius: 1)
			}
		)
	}
}

struct TripGridView_Previews: PreviewProvider {

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
		TripGridView(currentTrip: $entity)
	}
}
