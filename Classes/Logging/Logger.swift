//
//  Logger.swift
//  CarInfo
//
//  Created by Mihael Bercic on 12/07/2023.
//

import Foundation

class Logger {

	static func info(_ data: String) {
		insertLog(message: data, type: .info)
	}

	static func debug(_ data: String) {
		insertLog(message: data, type: .debug)
	}

	static func trace(_ data: String) {
		insertLog(message: data, type: .trace)
	}

	static func error(_ data: String) {
		insertLog(message: data, type: .error)
	}

	static func insertLog(message: String, type: LogType) {
		print(message)
		let logEntity = LogEntity(context: CoreDataManager.shared.viewContext).apply {
			$0.message = message
			$0.type = type.rawValue
			$0.timestamp = .now
		}
		CoreDataManager.shared.insert(entity: logEntity)
	}

}

enum LogType: Int16 {
	case info = 0
	case debug = 1
	case trace = 2
	case error = 3
}
