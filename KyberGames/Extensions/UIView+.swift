//
//  UIView+.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import Foundation
import UIKit

extension UIView {
  
  func addAndFitSubview(view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(view)
    let views = ["view": view]
    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: views))
    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views))
  }
  
  func roundedUsingWidth() {
    self.rounded(cornerRadius: self.frame.size.width/2)
  }
  
  func roundedUsingHeight() {
    self.rounded(cornerRadius: self.frame.size.height/2)
  }
  
  func rounded(cornerRadius: CGFloat) {
    self.layer.cornerRadius = cornerRadius
    self.layer.masksToBounds = true
  }
  
  func screenshot() -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
    drawHierarchy(in: self.bounds, afterScreenUpdates: false)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
  
  func applyShadow(
    apply: Bool,
    color: UIColor = UIColor.black,
    offset: CGSize = CGSize(width: 0.0, height: 2.0),
    opacity: Float = 0.2, radius: Float = 1.0,
    shadowRect: CGRect? = nil) {
      self.layer.shadowColor = apply ? color.cgColor : UIColor.white.withAlphaComponent(0.0).cgColor
      self.layer.shadowOffset = apply ? offset : CGSize(width: 0.0, height: 0.0)
      self.layer.shadowOpacity = apply ? opacity : 0.0
      self.layer.shadowRadius = apply ? CGFloat(radius) : 0.0
      self.layer.masksToBounds = false
      if let shadowRect = shadowRect {
        self.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
      }
    }
  
  func applyGlow(apply: Bool, color: UIColor) {
    self.layer.shadowColor = apply ? color.cgColor : UIColor.white.withAlphaComponent(0.0).cgColor
    self.layer.shadowOffset = CGSize.zero
    self.layer.shadowOpacity = apply ? 0.4 : 0.0
    self.layer.shadowRadius = apply ? 10.0 : 0.0
    self.layer.masksToBounds = false
  }
  
  var nibName: String {
    return type(of: self).description().components(separatedBy: ".").last! // to remove the module name and get only files name
  }
  
  func loadNib() -> UIView {
    let bundle = Bundle(for: type(of: self))
    let nib = UINib(nibName: self.nibName, bundle: bundle)
    return nib.instantiate(withOwner: self, options: nil)[0] as! UIView
  }
  
  func createDashedLine(startPoint: CGPoint, endPoint: CGPoint, color: UIColor, strokeLength: NSNumber, gapLength: NSNumber, width: CGFloat) {
//    let startPoint = CGPoint(x: bounds.minX, y: bounds.minY)
//    let endPoint = CGPoint(x: bounds.maxX, y: bounds.maxY)
    
    let shapeLayer = CAShapeLayer()
    
    shapeLayer.strokeColor = color.cgColor
    shapeLayer.lineWidth = width
    shapeLayer.lineDashPattern = [strokeLength, gapLength]
    
    let path = CGMutablePath()
    path.addLines(between: [startPoint, endPoint])
    shapeLayer.path = path
    layer.addSublayer(shapeLayer)
  }
  
  func drawDottedLine(start p0: CGPoint, end p1: CGPoint, view: UIView) {
    let shapeLayer = CAShapeLayer()
    shapeLayer.strokeColor = UIColor.lightGray.cgColor
    shapeLayer.lineWidth = 1
    shapeLayer.lineDashPattern = [7, 3] // 7 is the length of dash, 3 is length of the gap.
    
    let path = CGMutablePath()
    path.addLines(between: [p0, p1])
    shapeLayer.path = path
    view.layer.addSublayer(shapeLayer)
  }
  
  // MARK: IBInspectable
  
  @IBInspectable var borderColor: UIColor {
    get {
      let color = self.layer.borderColor ?? UIColor.white.cgColor
      return UIColor(cgColor: color) // not using this property as such
    }
    set {
      self.layer.borderColor = newValue.cgColor
    }
  }
  
  @IBInspectable var borderWidth: CGFloat {
    get {
      return self.layer.borderWidth
    }
    set {
      self.layer.borderWidth = newValue
    }
  }
  
  @IBInspectable var radius: CGFloat {
    get {
      return self.layer.cornerRadius
    }
    set {
      self.layer.cornerRadius = newValue
      self.rounded(cornerRadius: newValue)
    }
  }
}
