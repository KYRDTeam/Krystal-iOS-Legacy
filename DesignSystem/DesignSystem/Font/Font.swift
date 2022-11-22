//
//  Font.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import UIKit

public extension UIFont {
    
    static func karlaMedium(ofSize: CGFloat) -> UIFont {
        return UIFont(name: "Karla-Medium", size: ofSize)!
    }
    
    static func karlaReguler(ofSize: CGFloat) -> UIFont {
        return UIFont(name: "Karla-Regular", size: ofSize)!
    }
  
  static func karlaBold(ofSize: CGFloat) -> UIFont {
      return UIFont(name: "Karla-Bold", size: ofSize)!
  }
    
}
