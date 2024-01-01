//
//  MainView.swift
//  CarInfo
//
//  Created by Mihael Berčič on 31. 12. 23.
//

import SwiftUI

struct MainView: View {
    
    let tabs: [Tab] = [
        .init(type: .trips, iconName: "road.lanes.curved.left"),
        .init(type: .stats, iconName: "chart.bar.xaxis"),
        .init(type: .settings, iconName: "gear")
    ]
    
    @State var activeTabType: TabType = .trips
     
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationStack {
                switch(activeTabType) {
                    
                case .trips: TripListView()
                case .stats: Text("Statistics")
                case .settings: Text("Settings")
                }
            }
            Divider()
            HStack {
                ForEach(tabs, id: \.iconName) { tab in
                    let isActive = activeTabType == tab.type;
                    VStack(spacing: 5) {
                        Image(systemName: tab.iconName)
                        Text(tab.type.rawValue)
                            .font(.system(size: 12))
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(isActive ? Color.accentColor : Color.primary)
                    .onTapGesture {
                        activeTabType = tab.type
                    }
                }
            }
            .padding(.top, 5)
            .background(.ultraThinMaterial)
        }
    }
}

struct Tab: Equatable {
    
    let type: TabType
    let iconName: String
    
}

enum TabType: String {
    case trips = "Trips"
    case stats = "Stats"
    case settings = "Settings"
}


#Preview {
    MainView()
}
