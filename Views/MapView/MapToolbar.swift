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
		VStack(alignment: .center, spacing: 10) {
			Button {} label: {
				Image(systemName: "gear")
					.symbolRenderingMode(SymbolRenderingMode.hierarchical)
					.foregroundStyle(.foreground)
			}
			Divider()
				.frame(width: 35)
				.background(.foreground.opacity(0.1))
			Button {} label: {
				Image(systemName: "info")
					.symbolRenderingMode(SymbolRenderingMode.hierarchical)
					.foregroundStyle(.foreground)
			}
			Divider()
				.frame(width: 35)
				.background(.foreground.opacity(0.1))
			Button {
				isLogSheetPresented = true
			} label: {
				Image(systemName: "list.bullet")
					.symbolRenderingMode(SymbolRenderingMode.hierarchical)
					.foregroundStyle(.foreground)
			}
		}
		.padding([.top, .bottom], 10)
	}
}

struct MapToolbar_Previews: PreviewProvider {
	@State static var isLogSheetPresented = false
	static var previews: some View {
		MapToolbar(isLogSheetPresented: $isLogSheetPresented)
	}
}
