//
//  CameraHoleCover.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 18/07/2022.
//

import UIKit

class CameraHoleCover: UIView {
  
  let radius: CGFloat = 16
  let shapeLayer = CAShapeLayer()
  var lastPath = UIBezierPath().cgPath
  var lastCornerPath = UIBezierPath().cgPath
  
  // Corner config
  var cornerThickness: CGFloat = 4
  var cornerColor: UIColor = UIColor.Kyber.primaryGreenColor
  var cornerLength: CGFloat = 16
  var cornerRadius: CGFloat = 20
  let cornerLayer = CAShapeLayer()
  
  var holeFrame: CGRect = .zero {
    didSet {
      let newPath = calculatePath(holeFrame: holeFrame).cgPath
      animateShapeChange(lastPath: lastPath, newPath: newPath)
      lastPath = newPath
      
      let cornerPath = calculateCornerPath()
      animateCornersChange(lastPath: lastCornerPath, newPath: cornerPath)
      lastCornerPath = cornerPath
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    commonInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    commonInit()
  }
  
  func commonInit() {
    backgroundColor = .clear
    let size = frame.width * 3 / 4
    holeFrame = .init(x: frame.midX - size / 2, y: frame.midY - size / 2, width: size, height: size)
  }
  
  override func layoutSubviews() {
    drawView()
  }
  
  private func drawView() {
    shapeLayer.frame = self.bounds
    shapeLayer.fillRule = .evenOdd
    shapeLayer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
    let newPath = calculatePath(holeFrame: self.holeFrame).cgPath
    shapeLayer.path = newPath
    lastPath = newPath
    layer.addSublayer(shapeLayer)
    
    cornerLayer.fillColor = UIColor.clear.cgColor
    cornerLayer.strokeColor = cornerColor.cgColor
    let cornerPath = calculateCornerPath()
    cornerLayer.path = cornerPath
    lastCornerPath = cornerPath
    layer.addSublayer(cornerLayer)
  }
  
  private func calculateCornerPath() -> CGPath {
    let t2 = cornerThickness / 2
    let path = UIBezierPath()
    
    let minX = holeFrame.minX - 8
    let minY = holeFrame.minY - 8
    let maxX = holeFrame.maxX + 8
    let maxY = holeFrame.maxY + 8
    // Top left
    path.move(to: CGPoint(x: minX + t2, y: minY + cornerLength + cornerRadius + t2))
    path.addLine(to: CGPoint(x: minX + t2, y: minY + cornerRadius + t2))
    path.addArc(withCenter: CGPoint(x: minX + cornerRadius + t2, y: minY + cornerRadius + t2), radius: cornerRadius, startAngle: CGFloat.pi, endAngle: CGFloat.pi * 3 / 2, clockwise: true)
    path.addLine(to: CGPoint(x: minX + cornerLength + cornerRadius + t2, y: minY + t2))
    
    // Top right
    path.move(to: CGPoint(x: maxX - t2, y: minY + cornerLength + cornerRadius + t2))
    path.addLine(to: CGPoint(x: maxX - t2, y: minY + cornerRadius + t2))
    path.addArc(withCenter: CGPoint(x: maxX - cornerRadius - t2, y: minY + cornerRadius + t2), radius: cornerRadius, startAngle: 0, endAngle: CGFloat.pi * 3 / 2, clockwise: false)
    path.addLine(to: CGPoint(x: maxX - cornerLength - cornerRadius - t2, y: minY + t2))
    
    // Bottom left
    path.move(to: CGPoint(x: minX + t2, y: maxY - cornerLength - cornerRadius - t2))
    path.addLine(to: CGPoint(x: minX + t2, y: maxY - cornerRadius - t2))
    path.addArc(withCenter: CGPoint(x: minX + cornerRadius + t2, y: maxY - cornerRadius - t2), radius: cornerRadius, startAngle: CGFloat.pi, endAngle: CGFloat.pi / 2, clockwise: false)
    path.addLine(to: CGPoint(x: minX + cornerLength + cornerRadius + t2, y: maxY - t2))
    
    // Bottom right
    path.move(to: CGPoint(x: maxX - t2, y: maxY - cornerLength - cornerRadius - t2))
    path.addLine(to: CGPoint(x: maxX - t2, y: maxY - cornerRadius - t2))
    path.addArc(withCenter: CGPoint(x: maxX - cornerRadius - t2, y: maxY - cornerRadius - t2), radius: cornerRadius, startAngle: 0, endAngle: CGFloat.pi / 2, clockwise: true)
    path.addLine(to: CGPoint(x: maxX - cornerLength - cornerRadius - t2, y: maxY - t2))
    
    path.lineWidth = cornerThickness
    return path.cgPath
  }
  
  private func calculatePath(holeFrame: CGRect) -> UIBezierPath {
    let path = UIBezierPath()
    
    let outerRect = UIBezierPath(rect: bounds)
    path.append(outerRect)
    
    let innerRect = UIBezierPath(roundedRect: holeFrame, cornerRadius: radius)
    path.append(innerRect)
    
    return path
  }
  
  private func animateShapeChange(lastPath: CGPath, newPath: CGPath) {
    let basicAnimation = CABasicAnimation(keyPath: "path")
    
    basicAnimation.fromValue = lastPath
    basicAnimation.toValue = newPath
    basicAnimation.fillMode = .forwards
    basicAnimation.beginTime = CACurrentMediaTime()
    basicAnimation.isRemovedOnCompletion = false
    shapeLayer.add(basicAnimation, forKey: nil)
  }
  
  private func animateCornersChange(lastPath: CGPath, newPath: CGPath) {
    let basicAnimation = CABasicAnimation(keyPath: "path")
    
    basicAnimation.fromValue = lastPath
    basicAnimation.toValue = newPath
    basicAnimation.fillMode = .forwards
    basicAnimation.beginTime = CACurrentMediaTime()
    basicAnimation.isRemovedOnCompletion = false
    cornerLayer.add(basicAnimation, forKey: nil)
  }
  
}
