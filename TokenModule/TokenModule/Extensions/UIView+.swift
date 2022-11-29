//
//  UIView+.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 06/07/2022.
//

import UIKit

extension UIView {
  func rotate(angle: CGFloat) {
    let radians = angle / 180.0 * CGFloat.pi
    let rotation = self.transform.rotated(by: radians)
    self.transform = rotation
  }
}
