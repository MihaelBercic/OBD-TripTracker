//
//  CoordinateEntity+CoreDataProperties.swift
//  CarInfo
//
//  Created by Mihael Bercic on 01/07/2023.
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

}

extension CoordinateEntity: Identifiable {}
