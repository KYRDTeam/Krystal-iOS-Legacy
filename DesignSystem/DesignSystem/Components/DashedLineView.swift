//
//  DashedLineView.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit

@IBDesignable
public class DashedLineView: UIView {
    @IBInspectable public var perDashLength: CGFloat = 4.0
    @IBInspectable public var spaceBetweenDash: CGFloat = 4.0
    @IBInspectable public var dashColor: UIColor = AppTheme.current.separatorColor
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        let  path = UIBezierPath()
        if height > width {
            let  p0 = CGPoint(x: self.bounds.midX, y: self.bounds.minY)
            path.move(to: p0)
            
            let  p1 = CGPoint(x: self.bounds.midX, y: self.bounds.maxY)
            path.addLine(to: p1)
            path.lineWidth = width
            
        } else {
            let  p0 = CGPoint(x: self.bounds.minX, y: self.bounds.midY)
            path.move(to: p0)
            
            let  p1 = CGPoint(x: self.bounds.maxX, y: self.bounds.midY)
            path.addLine(to: p1)
            path.lineWidth = height
        }
        
        let dashes: [CGFloat] = [perDashLength, spaceBetweenDash]
        path.setLineDash(dashes, count: dashes.count, phase: 0.0)
        
        path.lineCapStyle = .butt
        dashColor.set()
        path.stroke()
    }
    
    private var width: CGFloat {
        return self.bounds.width
    }
    
    private var height: CGFloat {
        return self.bounds.height
    }
}
