//
//  RectangularDashedView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/8/20.
//

import UIKit

public class RectangularDashedView: UIView {
    
    @IBInspectable public var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable public var dashWidth: CGFloat = 0
    @IBInspectable public var dashColor: UIColor = .clear
    @IBInspectable public var dashLength: CGFloat = 0
    @IBInspectable public var betweenDashesSpace: CGFloat = 0
    
    var dashBorder: CAShapeLayer?
    
    public override func layoutSubviews() {
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
