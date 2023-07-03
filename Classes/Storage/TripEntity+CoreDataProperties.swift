//
//  TripEntity+CoreDataProperties.swift
//  CarInfo
//
//  Created by Mihael Bercic on 01/07/2023.
//
//

import CoreData
import Foundation

public extension TripEntity {

	@nonobjc class func fetchRequest() -> NSFetchRequest<TripEntity> {
		return NSFetchRequest<TripEntity>(entityName: "Trip")
	}

	@NSManaged var averageSpeed: Double
	@NSManaged var distance: Double
	@NSManaged var end: Date
	@NSManaged var start: Date
	@NSManaged var timestamp: Date
	@NSManaged var locations: Set<CoordinateEntity>

}

// MARK: Generated accessors for locations

public extension TripEntity {

	@objc(addLocationsObject:)
	@NSManaged func addToLocations(_ value: CoordinateEntity)

	@objc(removeLocationsObject:)
	@NSManaged func removeFromLocations(_ value: CoordinateEntity)

	@objc(addLocations:)
	@NSManaged func addToLocations(_ values: NSSet)

	@objc(removeLocations:)
	@NSManaged func removeFromLocations(_ values: NSSet)

}

extension TripEntity: Identifiable {}
