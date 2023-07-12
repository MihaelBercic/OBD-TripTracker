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

	private let entityQueue = Queue<CoreDataTuple>()

	init() {
		container.loadPersistentStores { _, error in
			if let error = error {
				print("Error with data loading \(error)")
			}
		}
		viewContext = container.viewContext
		Thread(block: process).start()
	}

	func insert(entity: NSManagedObject) {
		entityQueue.enqueue(CoreDataTuple(entity: entity, type: .insert))
	}

	func delete(entity: NSManagedObject) {
		entityQueue.enqueue(CoreDataTuple(entity: entity, type: .delete))
	}

	private func process() {
		while true {
			entityQueue.semaphore.wait()
			guard let tupleToProcess = entityQueue.dequeue() else { continue }
			let entity = tupleToProcess.entity
			do {
				if tupleToProcess.type == .insert {
					viewContext.insert(entity)
				} else {
					viewContext.delete(entity)
				}
				try viewContext.save()
				print("Processed CoreData queue tuple...")
			} catch {
				print(error)
			}
		}
	}

}

struct CoreDataTuple: Equatable {
	let entity: NSManagedObject
	let type: CoreDataManagmentType
}

enum CoreDataManagmentType {
	case insert
	case delete
	case dropAll
}
