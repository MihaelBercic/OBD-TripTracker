//
//  CarWidgetBundle.swift
//  CarWidget
//
//  Created by Mihael Bercic on 10/06/2023.
//

import WidgetKit
import SwiftUI

@main
struct CarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CarWidget()
        CarWidgetLiveActivity()
    }
}
