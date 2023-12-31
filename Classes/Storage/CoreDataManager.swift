//
//  CoreDataManager.swift
//  CarInfo
//
//  Created by Mihael Bercic on 12/07/2023.
//

import CoreData
import UIKit
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
    
    func performBackgroundTask(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            do {
                block(context)
                try context.save()
                
            } catch {
                fatalError("Failure to perform background context save \(error)")
            }
        }
    }
    
    func performMainTask(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        do {
            block(viewContext)
            try viewContext.save()
        } catch {
            fatalError("Failure to perform main context save \(error)")
        }
    }
    
}
