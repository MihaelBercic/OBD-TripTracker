//
//  TestEntities.swift
//  CarInfo
//
//  Created by Mihael Berčič on 1. 01. 24.
//

import Foundation

class TestEntities {
    
    static let shared = TestEntities()
    
    private init(){
        
    }
    
    public let tripEntity = TripEntity(context: CoreDataManager.shared.viewContext).apply {
        $0.start = .now - 3600
        $0.end = .now
        $0.startCity = "Ljubljana - Črnuče"
        $0.startCountry = "Slovenija"
        $0.endCity = "Ljubljana - Črnuče"
        $0.endCountry = "Slovenija"
    }
    
}
