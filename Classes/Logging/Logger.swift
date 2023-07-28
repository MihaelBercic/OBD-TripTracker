//
//  Logger.swift
//  CarInfo
//
//  Created by Mihael Bercic on 12/07/2023.
//

import Foundation
import CoreData

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
        CoreDataManager.shared.performBackgroundTask { context in
            let logEntity = LogEntity(context: context)
            logEntity.message = message
            logEntity.type = type.rawValue
            logEntity.timestamp = .now
        }
	}

}

enum LogType: Int16 {
	case info = 0
	case debug = 1
	case trace = 2
	case error = 3
}
