//
//  UIDevice+.swift
//  Utilities
//
//  Created by Com1 on 27/12/2022.
//

import UIKit

extension UIDevice {
  public static let isIphone5: Bool = UIScreen.main.bounds.size.height == 568.0
  public static let isIphone6: Bool = UIScreen.main.bounds.size.height == 667
  public static let isIphone6Plus: Bool = UIScreen.main.bounds.size.height == 736
  public static let isIphoneXOrLater: Bool = UIScreen.main.bounds.size.height >= 812
}
