//
//  CarInfoTests.swift
//  CarInfoTests
//
//  Created by Mihael Bercic on 10/06/2023.
//
//

@testable import CarInfo
import XCTest

final class CarInfoTests: XCTestCase {
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testEngineLoad() throws {
		let dataRead: [UInt8] = [0, 0, 0, 255, 0, 0, 0]
		let engineLoadPID = PIDs.engineLoad
		let relevantData = Array(dataRead[3 ... 2 + engineLoadPID.dataLength])
		let engineLoad = engineLoadPID.compute(relevantData)
		XCTAssert(engineLoad.value == 100.0)
	}

	func testEnqueue() throws {
		var queue = Queue<Int>()
		queue.enqueue(5)
		let enqueuedElement = queue.peek()
		assert(enqueuedElement == 5)
	}

	func testEnqueuMessage() throws {
		var queue = Queue<Message>()
		var message = Message(sid: "01", pids: PIDs.engineLoad, PIDs.engineSpeed)
		let readData = ["04", "10", "0C", "00", "04", "00", "00", "00"]
		message.responseData.append(contentsOf: readData)
		queue.enqueue(message)

		var dequeuedMessage = queue.dequeue()!
		dequeuedMessage.processMessage()
		print(dequeuedMessage.responseMeasurements)
		XCTAssert(!dequeuedMessage.responseMeasurements.isEmpty)
	}

	func testMessageEncoding() throws {
		let message = Message(sid: "01", pids: PIDs.engineLoad, PIDs.engineSpeed)
		XCTAssert(message.encodedRequest == "01 040C")
	}

	func testActualMessageParsing() throws {
		let encodedData = """
		  09

		  0: 41 AA BB CC DD EE

		  41 12 23 FF 33

		  1: BE DC EA DD GG
		"""

		let matches = encodedData.matches(of: /.*: (.*)/).flatMap { $0.1.split(separator: " ") }.dropFirst()
		print(matches)
		XCTAssert(matches.count == 10)
	}
}
