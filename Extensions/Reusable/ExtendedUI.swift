//
// Created by Mihael Bercic on 02/02/2022.
//

import Foundation

//
// Created by Mihael Bercic on 29/02/2020.
// Copyright (c) 2020 Mihael Bercic. All rights reserved.
//

import UIKit

protocol ViewSetup {
    func modifySubviews()
    func onInit()
    func setHierarchy()
    func setConstraints()

    func setup()
}

extension ViewSetup {
    func modifySubviews() {}

    func onInit() {}

    func setHierarchy() {}

    func setConstraints() {}
}

extension UIView {

    func cornerRadius(curve: CALayerCornerCurve, radius: Double, maskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]) {
        layer.cornerCurve = curve
        layer.cornerRadius = radius
        layer.maskedCorners = maskedCorners
        layer.masksToBounds = true
        clipsToBounds = true
    }

}

// Views
class CUIView: UIView {

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        if let delegate = self as? ViewSetup {
            delegate.setup()
        }

    }

    required init?(coder decoder: NSCoder) {
        fatalError("Not meant to be initialised this way")
    }
}

class CUITableView: UITableView {
    override init(frame: CGRect, style: Style) {
        super.init(frame: frame, style: style)
        if let delegate = self as? ViewSetup {
            delegate.setup()
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

class CUICollectionView: UICollectionView {

    override init(frame: CGRect = .zero, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        if let delegate = self as? ViewSetup {
            delegate.setup()
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

class CUITextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        if let delegate = self as? ViewSetup {
            delegate.setup()
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}


class CUIStackView: UIStackView {

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        if let delegate = self as? ViewSetup {
            delegate.setup()
        }
    }

    required init(coder: NSCoder) { super.init(coder: coder) }
}


// Reusable cells
class CUITableViewCell: UITableViewCell {

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if let delegate = self as? ViewSetup {
            delegate.setup()
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

class CUICollectionViewCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        if let delegate = self as? ViewSetup {
            delegate.setup()
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
}

extension UILabel {
    func respectSystemFont(_ forTextStyle: UIFont.TextStyle, traits: UIFontDescriptor.SymbolicTraits = []) {
        adjustsFontForContentSizeCategory = true
        font = UIFont.preferredFont(forTextStyle: forTextStyle).with(traits)
    }
}

extension UITextField {
    func respectSystemFont(_ forTextStyle: UIFont.TextStyle, traits: UIFontDescriptor.SymbolicTraits = []) {
        adjustsFontForContentSizeCategory = true
        font = UIFont.preferredFont(forTextStyle: forTextStyle).with(traits)
    }
}