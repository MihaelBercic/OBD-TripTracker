//
//  Queue.swift
//  CarInfo
//
//  Created by Mihael Bercic on 24/06/2023.
//

import Foundation

struct Queue<T> {
	private var elements = [T]()

	/// Put an element into the queue.
	///
	/// - Parameters:
	/// 	- element: Element of type T that will be put into the queue.
	mutating func enqueue(_ element: T) {
		elements.append(element)
	}

	mutating func dequeue() -> T? {
		return elements.isEmpty ? nil : elements.removeFirst()
	}

	func peek() -> T? {
		return elements.first
	}
}
