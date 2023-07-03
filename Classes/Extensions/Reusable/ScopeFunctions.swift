//
// Created by Mihael Bercic on 01/01/2020.
// Copyright (c) 2020 Regnum d.o.o. All rights reserved.
//

import Foundation
import UIKit

public protocol ScopeFunctions {}

extension ScopeFunctions {
	func apply(block: (Self) -> Void) -> Self {
		block(self)
		return self
	}

	mutating func use(_ block: (inout Self) -> Void) {
		block(&self)
	}
}

extension NSObject: ScopeFunctions {}

extension Array: ScopeFunctions {}

extension CGFloat: ScopeFunctions {}

extension String: ScopeFunctions {}
