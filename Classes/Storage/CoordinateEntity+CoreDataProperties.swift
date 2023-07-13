//
//  CoordinateEntity+CoreDataProperties.swift
//  CarInfo
//
//  Created by Mihael Bercic on 12/07/2023.
//
//

import CoreData
import Foundation

public extension CoordinateEntity {

	@nonobjc class func fetchRequest() -> NSFetchRequest<CoordinateEntity> {
		return NSFetchRequest<CoordinateEntity>(entityName: "Coordinate")
	}

	@NSManaged var latitude: NSDecimalNumber
	@NSManaged var longitude: NSDecimalNumber
	@NSManaged var speed: Int16
	@NSManaged var trip: TripEntity?

}

extension CoordinateEntity: Identifiable {}
