// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UINavigationController {
  func applyStyle() {
    navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    navigationBar.isTranslucent = false
    navigationBar.shadowImage = UIImage()
    navigationBar.barTintColor = UIColor.Kyber.navDark
    navigationBar.barStyle = UIBarStyle.black
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
  }

  public func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }

  public func popViewController(animated: Bool, completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    popViewController(animated: animated)
    CATransaction.commit()
  }

  public func popToRootViewController(animated: Bool, completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    popToRootViewController(animated: animated)
    CATransaction.commit()
  }
}
