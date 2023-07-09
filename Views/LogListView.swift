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
					let context = TripSingleton.shared.viewContext
					try context.execute(deleteRequest)
					try context.save()
				} catch {
					print(error)
				}
			}
			List {
				ForEach(logHistory.map { $0 as LogEntity }.sorted(by: { $0.timestamp > $1.timestamp })) { log in
					VStack(alignment: .leading) {
						Text(log.timestamp.formatted(date: .omitted, time: .standard))
							.font(.footnote)
							.opacity(0.5)
							.foregroundColor(log.type == 0 ? .blue : .red)
						Text(log.message)
					}.listRowInsets(.none)
				}
			}
			.scrollIndicators(.hidden)
			.listStyle(.plain)
		}.padding(30)
	}
}
