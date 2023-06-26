//
// Created by Mihael Bercic on 09/01/2020.
// Copyright (c) 2020 Regnum d.o.o. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    func connect(_ block: (AnchorStructure) -> ()) {
        translatesAutoresizingMaskIntoConstraints = false

        AnchorStructure().apply(block: block).use { structure in
            structure.topAnchor?.use { topAnchor.constraint(equalTo: $0, constant: structure.topConstant).isActive = true }
            structure.bottomAnchor?.use { bottomAnchor.constraint(equalTo: $0, constant: structure.bottomConstant).isActive = true }
            structure.leftAnchor?.use { leftAnchor.constraint(equalTo: $0, constant: structure.leftConstant).isActive = true }
            structure.rightAnchor?.use { rightAnchor.constraint(equalTo: $0, constant: structure.rightConstant).isActive = true }
            structure.leadingAnchor?.use { leadingAnchor.constraint(equalTo: $0, constant: structure.leadingConstant).isActive = true }
            structure.trailingAnchor?.use { trailingAnchor.constraint(equalTo: $0, constant: structure.trailingConstant).isActive = true }
            structure.centerXAnchor?.use { centerXAnchor.constraint(equalTo: $0, constant: structure.centerXConstant).isActive = true }
            structure.centerYAnchor?.use { centerYAnchor.constraint(equalTo: $0, constant: structure.centerYConstant).isActive = true }
            structure.widthAnchor?.use { widthAnchor.constraint(equalTo: $0, multiplier: structure.widthMultiplier, constant: structure.widthConstant ?? 0).isActive = true }
            structure.heightAnchor?.use { heightAnchor.constraint(equalTo: $0, multiplier: structure.heightMultiplier, constant: structure.heightConstant ?? 0).isActive = true }

            if (structure.widthAnchor == nil) {
                structure.widthConstant?.use { widthAnchor.constraint(equalToConstant: $0).isActive = true }
            }

            if (structure.heightAnchor == nil) {
                structure.heightConstant?.use { heightAnchor.constraint(equalToConstant: $0).isActive = true }
            }
        }
    }

    func pin(_ block: (AnchorStructure) -> ()) -> UIView {
        connect(block)
        return self
    }

    func putInto(view: UIView) {
        connect { structure in
            structure.topAnchor = view.topAnchor
            structure.bottomAnchor = view.bottomAnchor
            structure.leftAnchor = view.leftAnchor
            structure.rightAnchor = view.rightAnchor
        }
    }
}

class AnchorStructure: ScopeFunctions {

    var topAnchor:      NSLayoutYAxisAnchor?
    var bottomAnchor:   NSLayoutYAxisAnchor?
    var leftAnchor:     NSLayoutXAxisAnchor?
    var rightAnchor:    NSLayoutXAxisAnchor?
    var leadingAnchor:  NSLayoutXAxisAnchor?
    var trailingAnchor: NSLayoutXAxisAnchor?
    var centerXAnchor:  NSLayoutXAxisAnchor?
    var centerYAnchor:  NSLayoutYAxisAnchor?
    var widthAnchor:    NSLayoutDimension? = nil
    var heightAnchor:   NSLayoutDimension? = nil

    var topConstant:      CGFloat  = 0
    var bottomConstant:   CGFloat  = 0
    var leftConstant:     CGFloat  = 0
    var rightConstant:    CGFloat  = 0
    var leadingConstant:  CGFloat  = 0
    var trailingConstant: CGFloat  = 0
    var centerXConstant:  CGFloat  = 0
    var centerYConstant:  CGFloat  = 0
    var widthMultiplier:  CGFloat  = 1
    var heightMultiplier: CGFloat  = 1
    var widthConstant:    CGFloat? = nil
    var heightConstant:   CGFloat? = nil

}
