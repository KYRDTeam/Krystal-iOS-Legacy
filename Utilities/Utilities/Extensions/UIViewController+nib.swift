//
//  UIViewController+nib.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit

public extension UIViewController {
    
    static func instantiateFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>(_ viewType: T.Type) -> T {
            return T.init(nibName: String(describing: T.self), bundle: Bundle(for: T.self))
        }
        return instantiateFromNib(self)
    }
    
}

public extension UIViewController {
    func topMostViewController() -> UIViewController? {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}

public extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topMostViewController()
    }
}
