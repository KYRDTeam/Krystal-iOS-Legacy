//
//  CircleProgressView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 03/08/2022.
//

import UIKit

class CircularProgressView: UIView {
  
  private var circleLayer = CAShapeLayer()
  private var progressLayer = CAShapeLayer()
  private var startPoint = CGFloat(Double.pi / 12)
  private var endPoint = CGFloat(23 * Double.pi / 12)
    
  func createCircularPath() {
    let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: 10, startAngle: startPoint, endAngle: endPoint, clockwise: true)
    progressLayer.path = circularPath.cgPath
    progressLayer.fillColor = UIColor.clear.cgColor
    progressLayer.lineCap = .round
    progressLayer.lineWidth = 10
    progressLayer.strokeEnd = 0
    progressLayer.strokeColor = UIColor.Kyber.secondaryBg.cgColor
    layer.addSublayer(progressLayer)
  }
  
  func progressAnimation(duration: TimeInterval) {
    let circularProgressAnimation = CABasicAnimation(keyPath: "strokeEnd")
    circularProgressAnimation.duration = duration
    circularProgressAnimation.toValue = 0.9
    circularProgressAnimation.fillMode = .forwards
    circularProgressAnimation.isRemovedOnCompletion = false
    progressLayer.add(circularProgressAnimation, forKey: "progressAnim")
  }
  
  override func layoutSubviews() {
    createCircularPath()
  }
  
}
