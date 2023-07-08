//
//  TripEntity+CoreDataProperties.swift
//  CarInfo
//
//  Created by Mihael Bercic on 06/07/2023.
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
	@NSManaged var startCity: String
	@NSManaged var startCountry: String
	@NSManaged var endCity: String
	@NSManaged var endCountry: String
	@NSManaged var fuelStart: NSDecimalNumber
	@NSManaged var fuelEnd: NSDecimalNumber
	@NSManaged var locations: Set<CoordinateEntity>

}

// MARK: Generated accessors for locations

public extension TripEntity {

	@objc(insertObject:inLocationsAtIndex:)
	@NSManaged func insertIntoLocations(_ value: CoordinateEntity, at idx: Int)

	@objc(removeObjectFromLocationsAtIndex:)
	@NSManaged func removeFromLocations(at idx: Int)

	@objc(insertLocations:atIndexes:)
	@NSManaged func insertIntoLocations(_ values: [CoordinateEntity], at indexes: NSIndexSet)

	@objc(removeLocationsAtIndexes:)
	@NSManaged func removeFromLocations(at indexes: NSIndexSet)

	@objc(replaceObjectInLocationsAtIndex:withObject:)
	@NSManaged func replaceLocations(at idx: Int, with value: CoordinateEntity)

	@objc(replaceLocationsAtIndexes:withLocations:)
	@NSManaged func replaceLocations(at indexes: NSIndexSet, with values: [CoordinateEntity])

	@objc(addLocationsObject:)
	@NSManaged func addToLocations(_ value: CoordinateEntity)

	@objc(removeLocationsObject:)
	@NSManaged func removeFromLocations(_ value: CoordinateEntity)

	@objc(addLocations:)
	@NSManaged func addToLocations(_ values: NSOrderedSet)

	@objc(removeLocations:)
	@NSManaged func removeFromLocations(_ values: NSOrderedSet)

}

extension TripEntity: Identifiable {}
