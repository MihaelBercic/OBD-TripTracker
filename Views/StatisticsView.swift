//
//  StatisticsView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import SwiftUI
import WidgetKit

struct StatisticsView: View {

	let formatter: DateComponentsFormatter = DateComponentsFormatter().apply { formatter in
		formatter.unitsStyle = .abbreviated
		formatter.zeroFormattingBehavior = .dropAll
		formatter.allowedUnits = [.hour, .minute, .second]
	}

	let decimalFormatter = NumberFormatter().apply { formatter in
		formatter.maximumFractionDigits = 1
		formatter.minimumFractionDigits = 1
	}

	var body: some View {
		VStack(alignment: .leading) {
			Grid(verticalSpacing: 5) {
				GridRow(alignment: .top) {
					MetricView(identifier: "DISTANCE") {
						HStack(alignment: .bottom, spacing: 0) {
							Text("\(decimalFormatter.string(for: 20.4) ?? "-")")
								.fontWeight(.bold)
								.fontDesign(.rounded)
							Text("km").font(.footnote).foregroundColor(.secondary)
						}
					}
					MetricView(identifier: "DURATION") {
						Text(formatter.string(from: Date.now.distance(to: .now + 1000)) ?? "")
							.fontWeight(.bold)
							.fontDesign(.rounded)
					}
					MetricView(identifier: "AVG SPEED") {
						HStack(alignment: .top, spacing: 0) {
							Text(decimalFormatter.string(for: 100.0) ?? "-")
								.fontWeight(.bold)
								.fontDesign(.rounded)
							Text("km/h")
								.font(.footnote)
								.foregroundColor(.secondary)
						}
					}
				}
				Divider()
					.gridCellUnsizedAxes(.horizontal)
					.padding(10)
				GridRow(alignment: .top) {
					MetricView(identifier: "USED FUEL") {
						HStack(alignment: .bottom, spacing: 0) {
							Text(decimalFormatter.string(for: 0.8) ?? "-")
								.fontWeight(.bold)
								.fontDesign(.rounded)
							Text("L")
								.font(.footnote)
								.foregroundColor(.secondary)
						}
					}
					Spacer()
					MetricView(identifier: "MAX SPEED") {
						HStack(alignment: .top, spacing: 0) {
							Text(decimalFormatter.string(for: 234.2) ?? "-")
								.fontWeight(.bold)
								.fontDesign(.rounded)
							Text("km/h")
								.font(.footnote)
								.foregroundColor(.secondary)
						}
					}
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
	}
}

struct StatisticsView_Previews: PreviewProvider {
	static var previews: some View {
		StatisticsView()
			.previewLayout(.fixed(width: 300, height: 150))
	}
}

struct MetricView<Content: View>: View {

	let identifier: String
	@ViewBuilder let content: () -> Content

	var body: some View {
		VStack(spacing: 5) {
			content()
			Text(identifier)
				.font(.footnote)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
		}.frame(maxWidth: .infinity)
	}
}
