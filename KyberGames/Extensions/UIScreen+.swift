//
//  UIScreen.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

extension UIScreen {
  
  class var statusBarHeight: CGFloat {
    return statusBarFrame.height
  }
  
  class var statusBarFrame: CGRect {
    let window = UIApplication.shared.keyWindow
    if #available(iOS 13.0, *) {
      return window?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    } else {
      return UIApplication.shared.statusBarFrame
    }
  }
  
}
