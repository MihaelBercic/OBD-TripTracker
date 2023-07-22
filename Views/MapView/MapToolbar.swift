//
//  MapToolbar.swift
//  CarInfo
//
//  Created by Mihael Bercic on 08/07/2023.
//

import SwiftUI

struct MapToolbar: View {

	@Binding var isLogSheetPresented: Bool

	var body: some View {
		Grid(alignment: .center, horizontalSpacing: 10) {
			GridRow {
				Button {} label: {
					Image(systemName: "gearshape")
						.foregroundStyle(.foreground)
						.imageScale(.small)
				}

				Divider()
					.gridCellUnsizedAxes(.vertical)
					.frame(maxWidth: 1, maxHeight: .infinity)
					.background(.foreground)
					.opacity(0.01)

				Button {} label: {
					Image(systemName: "lanyardcard")
						.foregroundStyle(.foreground)
						.imageScale(.small)
				}

				Divider()
					.gridCellUnsizedAxes(.vertical)
					.frame(maxWidth: 1, maxHeight: .infinity)
					.background(.foreground)
					.opacity(0.01)

				Button {
					isLogSheetPresented = true
				} label: {
					Image(systemName: "clock")
						.foregroundStyle(.foreground)
						.imageScale(.small)
				}
			}
		}
		.padding(10)
	}
}

struct MapToolbar_Previews: PreviewProvider {
	@State static var isLogSheetPresented = false
	static var previews: some View {
		MapToolbar(isLogSheetPresented: $isLogSheetPresented)
	}
}
