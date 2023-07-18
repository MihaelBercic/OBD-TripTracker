//
//  TripCard.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import MapKit
import SwiftUI

struct TripCard: View {

	let tripEntity: TripEntity

	let formatter: DateComponentsFormatter = DateComponentsFormatter().apply { formatter in
		formatter.unitsStyle = .abbreviated
		formatter.zeroFormattingBehavior = .dropAll
		formatter.allowedUnits = [.hour, .minute, .second]
	}

	let decimalFormatter = NumberFormatter().apply { formatter in
		formatter.maximumFractionDigits = 1
		formatter.minimumFractionDigits = 1
	}

	var tripTime = "morning"
	var systemIconName = "moon.stars.fill"
	var primaryColor: Color = .white

	init(tripEntity: TripEntity) {
		self.tripEntity = tripEntity
		let dateComponents = Calendar.current.dateComponents([.hour], from: tripEntity.start)
		let time = dateComponents.hour ?? 0
		if time >= 22 || time < 5 {
			tripTime = "night"
			systemIconName = "moon.stars.fill"
		} else if time < 10 {
			tripTime = "morning"
			systemIconName = "sunrise"
			primaryColor = .orange
		} else if time < 18 {
			tripTime = "day"
			systemIconName = "sun.max.fill"
			primaryColor = .yellow
		} else if time < 22 {
			tripTime = "evening"
			systemIconName = "sunset.fill"
		}
	}

	var body: some View {
		VStack(spacing: 3) {
			HStack(alignment: .center) {
				Spacer()
				Text((tripEntity.start).formatted(date: .numeric, time: .omitted))
					.font(.caption2)
					.fontDesign(.rounded)
					.fontWeight(.semibold)
					.opacity(0.3)

				Image(systemName: systemIconName)
					.resizable()
					.frame(width: 16, height: 16)
					.symbolRenderingMode(.palette)
					.foregroundStyle(primaryColor, .yellow)
				Spacer()
			}.padding([.top], 5)

			HStack {
				VStack(alignment: .leading) {
					Text(tripEntity.startCity)
						.font(.body)
						.fontWeight(.semibold)
						.dynamicTypeSize(.small)
						.fontDesign(.rounded)
					Text(tripEntity.startCountry)
						.font(.footnote)
						.fontWeight(.semibold)
						.controlSize(.small)
						.fontDesign(.rounded)
						.dynamicTypeSize(.xSmall)
						.opacity(0.5)
				}
				Spacer()
				Text((tripEntity.start).formatted(date: .omitted, time: .shortened))
					.font(.footnote)
					.fontWeight(.semibold)
			}
			Divider().background(.foreground).opacity(0.25)
			HStack {
				VStack(alignment: .leading) {
					Text(tripEntity.endCity)
						.font(.body)
						.fontWeight(.semibold)
						.dynamicTypeSize(.small)
						.fontDesign(.rounded)
					Text(tripEntity.endCountry)
						.font(.footnote)
						.fontWeight(.semibold)
						.controlSize(.small)
						.fontDesign(.rounded)
						.dynamicTypeSize(.xSmall)
						.opacity(0.5)
				}
				Spacer()
				Text((tripEntity.end).formatted(date: .omitted, time: .shortened))
					.font(.footnote)
					.fontWeight(.semibold)
			}
		}
	}

}

struct TripCard_Previews: PreviewProvider {

	public static let tripEntity = TripEntity(context: CoreDataManager.shared.viewContext).apply {
		$0.start = .now - 3600
		$0.end = .now
		$0.startCity = "Ljubljana"
		$0.startCountry = "Slovenija"
		$0.endCity = "Portorož"
		$0.endCountry = "Slovenija"
	}

	static var previews: some View {
		let _ = print(tripEntity)
		TripCard(tripEntity: tripEntity)
			.previewLayout(.fixed(width: 150, height: 200))
			.background(.secondary)
	}
}
