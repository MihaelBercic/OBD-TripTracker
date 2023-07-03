//
//  Logger.swift
//  CarInfo
//
//  Created by Mihael Bercic on 03/07/2023.
//

import Foundation

class Logger {

	static let shared = Logger()
	private let context = TripSingleton.shared.viewContext

	func info(_ element: Any) {
		print("ℹ️ \(element)")
		insertLog(type: .info, message: "\(element)")
	}

	func error(_ element: Any) {
		print("❌ \(element)")
		insertLog(type: .error, message: "\(element)")
	}

	private func insertLog(type: MessageType, message: String) {
		let logEntity = LogEntity(context: context)
		logEntity.message = message
		logEntity.type = type.rawValue
		logEntity.timestamp = .now
		do {
			context.insert(logEntity)
			try context.save()
		} catch {
			print(error)
		}
	}

}

enum MessageType: Int16 {
	case info = 0
	case error = 1
}
