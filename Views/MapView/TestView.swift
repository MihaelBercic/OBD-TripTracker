//
//  TestView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 08/07/2023.
//

import MapKit
import SwiftUI

struct TestView: View {
	@State private var present = true
	@State private var height: CGFloat = .zero

	var body: some View {
		Map(mapRect: .constant(.world))
			.ignoresSafeArea()
			.overlay(alignment: .bottomLeading) {
				Image(systemName: "xmark")
					.ignoresSafeArea()
					.font(.system(size: 50))
					.offset(y: -height - 10)
			}
			.sheet(isPresented: $present) {
				GeometryReader { geometry in
					VStack {
						Text("HI")
					}
					.presentationDetents([.fraction(0.1), .medium])
					.presentationDragIndicator(.visible)
					.presentationBackgroundInteraction(.enabled)
					.interactiveDismissDisabled()
					.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
					.onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
						height = newHeight
					}
				}
			}
	}
}

struct InnerHeightPreferenceKey: PreferenceKey {
	static var defaultValue: CGFloat = .zero
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = nextValue()
	}
}

struct TestView_Previews: PreviewProvider {
	static var previews: some View {
		TestView()
	}
}
