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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSave(_:)),
                                               name: NSManagedObjectContext.didSaveObjectsNotification,
                                               object: nil)
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
    
    @objc private func didSave(_ notification: Notification) {
        DispatchQueue.main.async {
            self.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
}
