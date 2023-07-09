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

	init(tripEntity: TripEntity) {
		self.tripEntity = tripEntity
	}

	var body: some View {
		VStack {
			Text((tripEntity.start).formatted(date: .numeric, time: .shortened))
				.font(.footnote)
				.fontWeight(.semibold)
				.opacity(0.5)

			HStack(alignment: .center) {
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
				Image(systemName: "arrow.right")
				Spacer()
				VStack(alignment: .trailing) {
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
			}
		}
	}

}

struct TripCard_Previews: PreviewProvider {

	public static let tripEntity = TripEntity(context: TripSingleton.shared.viewContext).apply {
		$0.start = .now - 3600
	}

	static var previews: some View {
		let _ = print(tripEntity)
		TripCard(tripEntity: tripEntity)
			.previewLayout(.fixed(width: 200, height: 100))
	}
}
