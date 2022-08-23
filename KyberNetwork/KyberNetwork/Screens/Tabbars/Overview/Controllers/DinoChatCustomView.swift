//
//  TestCustomView.swift
//  KyberNetwork
//
//  Created by Com1 on 15/08/2022.
//

import UIKit

class DinoChatCustomView: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.clear
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    backgroundColor = UIColor.clear
  }

  override func draw(_ rect: CGRect) {
    let size = self.bounds.size
    let bigCornerRadius: CGFloat = 16
    let smallCornerRadius: CGFloat = 5
    let h = size.height - 22
    let p1 = CGPoint(x:self.bounds.origin.x, y:self.bounds.origin.y + bigCornerRadius)//self.bounds.origin
    let p2 = CGPoint(x:self.bounds.origin.x + bigCornerRadius, y:self.bounds.origin.y)
    let p3 = CGPoint(x:p1.x + size.width - bigCornerRadius, y:p2.y)
    let p4 = CGPoint(x:p1.x + size.width, y:p1.y)
    let p5 = CGPoint(x:p4.x, y:p3.y + h - bigCornerRadius)
    let p6 = CGPoint(x:p3.x, y:p3.y + h)
    let p7 = CGPoint(x:111, y:p6.y)
    let p8 = CGPoint(x:93, y:p3.y + size.height - 5)
    
    let p9 = CGPoint(x:89, y:p8.y - 2)
    let p10 = CGPoint(x:95, y:p6.y)
    let p11 = CGPoint(x:p2.x, y:p6.y)
    let p12 = CGPoint(x:p1.x, y:p5.y)

    let path = UIBezierPath()
    path.move(to: p1)
    path.addQuadCurve(to: p2, controlPoint: self.bounds.origin)
    path.addLine(to: p3)
    path.addQuadCurve(to: p4, controlPoint: CGPoint(x: p4.x, y: p3.y))
    path.addLine(to: p5)
    path.addQuadCurve(to: p6, controlPoint: CGPoint(x: p5.x, y: p6.y))
    path.addLine(to: p7)
    path.addLine(to: p8)
    path.addQuadCurve(to: p9, controlPoint: CGPoint(x: p9.x + 1, y: p8.y + 2.5))
    path.addLine(to: p10)
    path.addLine(to: p11)
    path.addQuadCurve(to: p12, controlPoint: CGPoint(x: p1.x, y: p6.y))

    path.close()
    UIColor(named: "investButtonBgColor")!.set()
    path.fill()
  }

}
