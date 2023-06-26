//
// Created by Mihael Bercic on 29/02/2020.
// Copyright (c) 2020 Mihael Bercic. All rights reserved.
//

import Foundation
import UIKit

protocol Bindable {
    associatedtype AssociatedType: Comparable
    var observable: Observable<AssociatedType> { get }
    var selector:   Selector { get }
    func bind(with: Observable<AssociatedType>)
}

class Observable<T: Equatable>: ScopeFunctions {

    private var connected:     [Observable]   = []
    private var didSetActions: [(T, T) -> ()] = []

    init(_ defaultValue: T, _ onChange: @escaping (_ oldValue: T, _ newValue: T) -> () = { _, _ in }) {
        value = defaultValue
        didSetActions.append(onChange)
    }

    var value: T {
        didSet {
            if value != oldValue {
                didSetActions.forEach { (closure: (T, T) -> ()) in closure(oldValue, value) }
                notify()
            }
        }
    }


    /// Notifies every connected observable.
    private func notify() {
        connected.forEach { $0.value = value }
    }

    /// Add the observable to the connected observables.
    func bindBiDirectionally(with: Observable<T>) {
        with.connected.append(self);
        connected.append(with)
    }

    func bind(to: Observable<T>) {
        to.connected.append(self)
    }

    func onValueChanged(_ action: @escaping (_ oldValue: T, _ newValue: T) -> ()) {
        didSetActions.append(action)
    }
}


extension Bindable where Self: NSObject {

    func bind(with: Observable<AssociatedType>) {
        observable.bindBiDirectionally(with: with);
        addTarget()
    }

    func addTarget() {
        guard let self = self as? UIControl else { return }
        self.addTarget(self, action: selector, for: .allEditingEvents)
    }
}


/// Customized UIControls
class ObservableTextField: UITextField, Bindable {
    lazy var observable: Observable<String> = Observable<String>("") { _, new in self.text = new }
    lazy var selector: Selector = #selector(onChange)

    @objc func onChange() { observable.value = text ?? "" }
}

class ObservableLabel: UILabel, Bindable {
    lazy var observable: Observable<String> = Observable<String>("") { _, new in self.text = new }
    lazy var selector: Selector = #selector(onChange)

    @objc func onChange() { observable.value = text ?? "" }
}
