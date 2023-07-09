//
//  TripRepresented.swift
//  CarInfo
//
//  Created by Mihael Bercic on 08/07/2023.
//

import Foundation

class TripRepresented {

	let startedAt: Date
	let endedAt: Date
	let distance: Double

	init(tripEntity: TripEntity) {
		startedAt = tripEntity.start
		endedAt = tripEntity.end
		distance = tripEntity.distance
	}

}
