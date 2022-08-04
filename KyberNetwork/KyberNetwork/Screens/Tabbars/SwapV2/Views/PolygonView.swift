//
//  PolygonView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 04/08/2022.
//

import UIKit

class PolygonView: UIView {
  
  override func layoutSubviews() {
    drawView()
  }
  
  private func drawView() {
    let shapeLayer = CAShapeLayer()
    shapeLayer.frame = self.bounds
    
    let w = bounds.width
    let h = bounds.height
    
    let path = UIBezierPath()
    path.move(to: .init(x: 0, y: h/2))
    path.addLine(to: .init(x: 3*h/8, y: 0))
    path.addLine(to: .init(x: w - 3*h/8, y: 0))
    path.addLine(to: .init(x: w, y: h/2))
    path.addLine(to: .init(x: w - 3*h/8, y: h))
    path.addLine(to: .init(x: 3*h/8, y: h))
    path.addLine(to: .init(x: 0, y: h/2))
    path.close()
    
    let fillLayer = CAShapeLayer()
    fillLayer.path = path.cgPath
    fillLayer.fillColor = UIColor.Kyber.primaryGreenColor.cgColor
    layer.addSublayer(fillLayer)
  }
}
