//
// Created by Mihael Bercic on 28/02/2020.
// Copyright (c) 2020 Mihael Bercic. All rights reserved.
//

import Foundation
import UIKit

extension Int {
	var asDecimal: NSDecimalNumber { NSDecimalNumber(value: self) }
	var asNSNumber: NSNumber { NSNumber(value: self) }
}

extension Double {
	var asDecimal: NSDecimalNumber { NSDecimalNumber(value: self) }
	var asNSNumber: NSNumber { NSNumber(value: self) }
}

extension UITextField {
	func setPadding(_ left: CGFloat = 0, _ right: CGFloat = 0) {
		if left > 0 {
			let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: left, height: frame.size.height))
			leftView = paddingView
			leftViewMode = .always
		}
		if right > 0 {
			let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: right, height: frame.size.height))
			rightView = paddingView
			rightViewMode = .always
		}
	}
}

extension UIColor {

	convenience init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int = UInt64()
		Scanner(string: hex).scanHexInt64(&int)
		let a, r, g, b: UInt64
		switch hex.count {
		case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default: (a, r, g, b) = (255, 0, 0, 0)
		}
		self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
	}
}

func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
	(from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
}

func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
	sqrt(CGPointDistanceSquared(from: from, to: to))
}

extension StringProtocol {
	subscript(offset: Int) -> Character {
		self[index(startIndex, offsetBy: offset)]
	}
}

extension String {
	func localized(withComment: String = "") -> String {
		NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
	}
}

extension UIColor {

	func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
		return adjust(by: abs(percentage))
	}

	func darker(by percentage: CGFloat = 30.0) -> UIColor? {
		return adjust(by: -1 * abs(percentage))
	}

	func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
			return UIColor(red: min(red + percentage / 100, 1.0),
			               green: min(green + percentage / 100, 1.0),
			               blue: min(blue + percentage / 100, 1.0),
			               alpha: alpha)
		} else {
			return nil
		}
	}
}

extension UIFont {
	var bold: UIFont {
		return with(.traitBold)
	}

	var italic: UIFont {
		return with(.traitItalic)
	}

	var boldItalic: UIFont {
		return with([.traitBold, .traitItalic])
	}

	func with(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
		guard let descriptor = fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(fontDescriptor.symbolicTraits)) else {
			return self
		}
		return UIFont(descriptor: descriptor, size: 0)
	}

	func without(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
		guard let descriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.subtracting(UIFontDescriptor.SymbolicTraits(traits))) else {
			return self
		}
		return UIFont(descriptor: descriptor, size: 0)
	}
}

extension Set {
	subscript(offset: Int) -> Element {
		self[index(startIndex, offsetBy: offset)]
	}
}

extension Date {

	func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
		calendar.isDate(self, equalTo: date, toGranularity: component)
	}

	func isInSameYear(date: Date) -> Bool { isEqual(to: date, toGranularity: .year) }

	func isInSameMonth(date: Date) -> Bool { isEqual(to: date, toGranularity: .month) }

	func isInSameDay(date: Date) -> Bool { isEqual(to: date, toGranularity: .day) }

	func isInSameWeek(date: Date) -> Bool { isEqual(to: date, toGranularity: .weekOfYear) }

	var isInThisYear: Bool { isInSameYear(date: Date()) }
	var isInThisMonth: Bool { isInSameMonth(date: Date()) }
	var isInThisWeek: Bool { isInSameWeek(date: Date()) }

	var isInYesterday: Bool { Calendar.current.isDateInYesterday(self) }
	var isInToday: Bool { Calendar.current.isDateInToday(self) }
	var isInTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }

	var isInTheFuture: Bool { self > Date() }
	var isInThePast: Bool { self < Date() }
}

public extension UInt8 {
	var asBinary: String {
		let binaryRepresentation = String(self, radix: 2)
		let requiredZeros = 8 - binaryRepresentation.count
		return repeatElement("0", count: requiredZeros) + binaryRepresentation
	}
}

extension Array {
	func chunked(into size: Int) -> [[Element]] {
		return stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
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
