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

	var isEmpty: Bool {
		elements.isEmpty
	}

	/// [BLOCKING] Put an element into the queue.
	///
	/// - Parameters:
	/// 	- element: Element of type T that will be put into the queue.
	func enqueue(_ element: T, quietly: Bool = false) {
		lock.withLock {
			elements.append(element)
			if !quietly {
				semaphore.signal()
			}
		}
	}

	func dequeue() -> T? {
		semaphore.wait()
		return lock.withLock { elements.isEmpty ? nil : elements.removeFirst() }
	}

	func peek() -> T? {
		return lock.withLock { elements.first }
	}

	func contains(_ element: T) -> Bool {
		return lock.withLock { elements.contains { $0 == element }}
	}

	func clear() {
		lock.withLock {
			elements = []
		}
	}
}
