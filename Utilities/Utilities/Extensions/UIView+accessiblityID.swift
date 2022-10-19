//
//  UIView+accessiblityID.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit

@IBDesignable
public extension UIView {
  
  @IBInspectable public var accessibilityID: String? {
    get {
      accessibilityIdentifier
    }
    set {
      accessibilityIdentifier = newValue
    }
  }
  
}
