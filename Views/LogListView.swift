//
//  LogListView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 05/07/2023.
//

import CoreData
import SwiftUI

struct LogListView: View {

	var logHistory: FetchedResults<LogEntity>

	var body: some View {
		VStack(alignment: .leading) {
			Text("Logs")
				.font(.title)
				.fontWeight(.bold)
				.dynamicTypeSize(.xLarge)
			Button("Clear") {
				do {
					let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LogEntity")

					let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
					deleteRequest.resultType = .resultTypeObjectIDs
					let context = CoreDataManager.shared.viewContext
					let deleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
					if let objectIDs = deleteResult?.result as? [NSManagedObjectID] {
						NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [context])
					}
				} catch {
					print(error)
				}
			}
			List {
				ForEach(logHistory.map { $0 as LogEntity }.sorted(by: { $0.timestamp > $1.timestamp })) { log in
					VStack(alignment: .leading) {
						Text(log.timestamp.formatted(date: .omitted, time: .standard))
							.font(.footnote)
							.foregroundColor(log.type == 0 ? .blue : .red)
						Text(log.message)
					}
					.listRowInsets(.none)
				}
			}
			.scrollIndicators(.hidden)
			.listStyle(.plain)
		}
		.padding(30)
	}
}
