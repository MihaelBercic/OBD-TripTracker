//
//  LogEntity+CoreDataProperties.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//
//

import CoreData
import Foundation

public extension LogEntity {

	@nonobjc class func fetchRequest() -> NSFetchRequest<LogEntity> {
		return NSFetchRequest<LogEntity>(entityName: "LogEntity")
	}

	@NSManaged var timestamp: Date
	@NSManaged var message: String
	@NSManaged var type: Int16

}

extension LogEntity: Identifiable {}
