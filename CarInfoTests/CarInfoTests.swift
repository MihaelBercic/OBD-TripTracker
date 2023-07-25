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
		let engineLoadPID = Packets.engineLoad
		let relevantData = Array(dataRead[3 ... 2 + engineLoadPID.dataLength])
		let engineLoad = engineLoadPID.compute(relevantData)
		XCTAssert(engineLoad.value == 100.0)
	}

	func testEnqueue() throws {
		let queue = Queue<Int>()
		queue.enqueue(5)
		let enqueuedElement = queue.peek()
		assert(enqueuedElement == 5)
	}

	func testShortMessageParsing() throws {
		let responseManager = ResponseManager()
		let encodedData = "7E8 03 41 2F E8"
		let lines = encodedData.split(separator: "\r\n")
		for line in lines {
			responseManager.prepare(message: String(line))
		}
	}

	func testActualMessageParsing() throws {
		let measurementQueue = Queue<MeasuredValue>()
		let responseManager = ResponseManager()
		let encodedData = """
		7E8 10 0A 41 2F E8 46 3F 1F
		7E8 21 00 0E 0D 00 00 00 00

		7E9 10 08 41 46 3F 1F 00 0E
		7E9 21 0D 00 00 00 00 00 00
		"""
		let lines = encodedData.split(separator: /\r\n|\n/)
		lines.forEach { responseManager.prepare(message: String($0)) }
		XCTAssert(measurementQueue.peek() != nil)
	}

	func testChunkedArray() throws {
		let array = [0, 0, 0, 0, 0, 0, 0, 0, 0]
		let chunked = array.chunked(into: 5)
		XCTAssert(chunked.count == 2 && chunked[0].count == 5 && chunked[1].count == 4)
	}

	func testStructPass() throws {
		var trip: Trip? = Trip()
		trip?.use {
			$0.car = "XCODE"
			print($0)
			XCTAssert($0.car == "XCODE")
		}
		XCTAssert(trip?.car == "XCODE")
		print(trip?.car ?? "UNKNOWN")
	}

	func testDequeue() throws {
		let lastSpeedMeasurement: Date = .now - 5
		let timeDifference = abs(Date.now.distance(to: lastSpeedMeasurement))
		let speedKMH = 100.0
		let speedMS = speedKMH / 3.6
		let movedMeters = speedMS * timeDifference

		print("\(Date.now) vs \(lastSpeedMeasurement) = \(timeDifference) moved \(movedMeters)")
	}

	func testTrip() {
		var trip = Trip()
		trip.fuelTankLevel = 9.0
		XCTAssert(trip.startFuelTankLevel == 9.0)
	}
    
    func testDateDifference() {
        let start: Date = .now
        usleep(1_000_000)
        print("Time difference: \(start.distance(to: .now))")
    }

}
