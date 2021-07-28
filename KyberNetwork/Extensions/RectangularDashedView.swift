//
//  RectangularDashedView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/8/20.
//

import UIKit

class RectangularDashedView: UIView {

  @IBInspectable var cornerRadius: CGFloat = 0 {
    didSet {
      layer.cornerRadius = cornerRadius
      layer.masksToBounds = cornerRadius > 0
    }
  }
  @IBInspectable var dashWidth: CGFloat = 0
  @IBInspectable var dashColor: UIColor = .clear
  @IBInspectable var dashLength: CGFloat = 0
  @IBInspectable var betweenDashesSpace: CGFloat = 0
  
  var dashBorder: CAShapeLayer?
  
  override func layoutSubviews() {
    super.layoutSubviews()
    dashBorder?.removeFromSuperlayer()
    let dashBorder = CAShapeLayer()
    dashBorder.lineWidth = dashWidth
    dashBorder.strokeColor = dashColor.cgColor
    dashBorder.lineDashPattern = [dashLength, betweenDashesSpace] as [NSNumber]
    dashBorder.frame = bounds
    dashBorder.fillColor = nil
    if cornerRadius > 0 {
      dashBorder.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    } else {
      dashBorder.path = UIBezierPath(rect: bounds).cgPath
    }
    layer.addSublayer(dashBorder)
    self.dashBorder = dashBorder
  }
}
