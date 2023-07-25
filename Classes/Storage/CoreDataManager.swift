//
//  CoreDataManager.swift
//  CarInfo
//
//  Created by Mihael Bercic on 12/07/2023.
//

import CoreData
import Foundation

class CoreDataManager {

	static let shared = CoreDataManager()
	let container = NSPersistentContainer(name: "CarInfo")

	let viewContext: NSManagedObjectContext

	private init() {
		container.loadPersistentStores { _, error in
			if let error = error {
				print("Error with data loading \(error)")
			}
		}
        viewContext = container.viewContext
        
	}

	func insert(entity _: NSManagedObject) {
        viewContext.performAndWait {
            self.saveContext()
        }
	}

	func delete(entity: NSManagedObject) {
        viewContext.performAndWait {
            self.viewContext.delete(entity)
            self.saveContext()
        }
	}

	private func saveContext() {
		do {
            if viewContext.hasChanges {
                try viewContext.save()
            }

		} catch {
			print(error)
		}
	}

}
