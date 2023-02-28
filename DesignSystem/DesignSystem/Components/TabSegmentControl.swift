//
//  TabSegmentControl.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation
import UIKit

open class SegmentedControl: UISegmentedControl {
    public var isSetupHighlight = false
    
    public func removeBorder() {
        let background = UIImage.getSegRect(color: UIColor.clear.cgColor, andSize: self.bounds.size) // segment background color and size
        self.setBackgroundImage(background, for: .normal, barMetrics: .default)
        self.setBackgroundImage(background, for: .selected, barMetrics: .default)
        self.setBackgroundImage(background, for: .highlighted, barMetrics: .default)
        
        let deviderLine = UIImage.getSegRect(color: UIColor.clear.cgColor, andSize: CGSize(width: 1.0, height: 5))
        self.setDividerImage(deviderLine, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        self.setTitleTextAttributes([
            NSAttributedString.Key.foregroundColor: AppTheme.current.secondaryTextColor,
            NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 16)], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: AppTheme.current.primaryTextColor, NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 16)], for: .selected)
    }
    
    public func highlightSelectedSegment(parentWidth: CGFloat? = nil, width: CGFloat? = nil) {
        guard !isSetupHighlight else { return }
        removeBorder()
        let lineWidth: CGFloat = (parentWidth ?? self.frame.size.width) / CGFloat(self.numberOfSegments)
        let lineHeight: CGFloat = 2.0
        let lineXPosition = CGFloat(selectedSegmentIndex * Int(lineWidth)) + (lineWidth - (width ?? lineWidth)) / 2
        let lineYPosition = self.bounds.size.height - 6.0
        let underlineFrame = CGRect(x: lineXPosition, y: lineYPosition, width: width ?? lineWidth, height: lineHeight)
        let underLine = UIView(frame: underlineFrame)
        underLine.backgroundColor = UIColor(named: "buttonBackgroundColor")
        underLine.tag = 1
        self.addSubview(underLine)
        isSetupHighlight = true
    }
    
    public func underlinePosition() {
        guard let underLine = self.viewWithTag(1) else { return }
        let xPosition = (self.frame.width / CGFloat(self.numberOfSegments)) * CGFloat(selectedSegmentIndex)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            underLine.frame.origin.x = xPosition
        })
    }
    
    public func underlineCenterPosition() {
        guard let underLine = self.viewWithTag(1) else { return }
        let segmentWidth = self.frame.width / CGFloat(self.numberOfSegments)
        let xPosition = segmentWidth * CGFloat(selectedSegmentIndex) + (segmentWidth - underLine.frame.size.width) / 2
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            underLine.frame.origin.x = xPosition
        })
    }
}

extension UIImage {
    class func getSegRect(color: CGColor, andSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color)
        let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        context?.fill(rectangle)
        
        let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rectangleImage!
    }
}
