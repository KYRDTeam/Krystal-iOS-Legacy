//
//  String+.swift
//  Utilities
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import UIKit

public extension String {
    
    func withLineSpacing(lineSpacing: CGFloat = 4) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range: NSMakeRange(0, attributedString.length))
        return attributedString
    }
  
  
    
}


public extension Optional where Wrapped == String {
  
  func whenNilOrEmpty(_ value: String) -> String {
    if let unwrapped = self, !unwrapped.isEmpty {
      return unwrapped
    }
    return value
  }
  
}
