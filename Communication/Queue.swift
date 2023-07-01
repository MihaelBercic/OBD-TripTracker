//
//  Queue.swift
//  CarInfo
//
//  Created by Mihael Bercic on 24/06/2023.
//

import Foundation

class Queue<T: Equatable> {

	let semaphore = DispatchSemaphore(value: 0)
	private var lock = NSLock()

	private var elements = [T]()

	/// Put an element into the queue.
	///
	/// - Parameters:
	/// 	- element: Element of type T that will be put into the queue.
	func enqueue(_ element: T) {
		lock.withLock {
			elements.append(element)
			semaphore.signal()
		}
	}

	func dequeue() -> T? {
		return lock.withLock { elements.isEmpty ? nil : elements.removeFirst() }
	}

	func peek() -> T? {
		return lock.withLock { elements.first }
	}

	func contains(_ element: T) -> Bool {
		return lock.withLock { elements.contains { $0 == element }}
	}

	func moveToTheBack() {
		guard let element = dequeue() else { return }
		enqueue(element)
	}

	func clear() {
		lock.withLock {
			elements = []
		}
	}
}

extension NSLock {

	@discardableResult
	func with<T>(_ block: () throws -> T) rethrows -> T {
		lock()
		defer { unlock() }
		return try block()
	}

}
