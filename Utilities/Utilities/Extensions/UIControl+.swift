//
//  UIControl+.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/12/2022.
//

import UIKit

class ClosureSleeve {
  let closure: () -> ()
  
  init(attachTo: AnyObject, closure: @escaping () -> ()) {
    self.closure = closure
    objc_setAssociatedObject(attachTo, "[\(arc4random())]", self, .OBJC_ASSOCIATION_RETAIN)
  }
  
  @objc func invoke() {
    closure()
  }
}

public extension UIControl {
  func addAction(for controlEvents: UIControl.Event = .primaryActionTriggered, action: @escaping () -> ()) {
    let sleeve = ClosureSleeve(attachTo: self, closure: action)
    addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
  }
}
