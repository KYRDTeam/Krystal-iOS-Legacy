//
//  UIScreen+statusBar.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit

public extension UIScreen {
    
    class var statusBarHeight: CGFloat {
        return statusBarFrame.height
    }
    
    class var bottomPadding: CGFloat {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
        }
        return 0
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
