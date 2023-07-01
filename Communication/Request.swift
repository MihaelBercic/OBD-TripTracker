//
//  Request.swift
//  CarInfo
//
//  Created by Mihael Bercic on 28/06/2023.
//

import Foundation

struct Request: Equatable {
	let sid: String
	let pids: [PIDs]
	let encodedRequest: String

	init(sid: String, pids: [PIDs]) {
		self.sid = sid
		self.pids = pids
		encodedRequest = "\(sid) \(pids.map { String(format: "%02X", $0.rawValue) }.joined())"
	}
}

extension Request {
	init(sid: String, _ pids: PIDs...) {
		self.init(sid: sid, pids: pids)
	}
}
