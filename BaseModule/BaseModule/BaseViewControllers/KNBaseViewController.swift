//
//  KNBaseViewController.swift
//  BaseModule
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit
import Utilities
import DesignSystem

open class KNBaseViewController: UIViewController, UIGestureRecognizerDelegate {

  @IBOutlet public weak var topBarHeight: NSLayoutConstraint?
  let titleHeight: CGFloat = 24
  let titleVerticalPadding: CGFloat = 26
  
  override open var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override open func viewDidLoad() {
    super.viewDidLoad()
    
    topBarHeight?.constant = UIScreen.statusBarHeight + titleHeight + titleVerticalPadding * 2
  }
  
  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.dismissTutorialOverlayer()
  }
  
  var isVisible: Bool {
    return self.viewIfLoaded?.window != nil
  }
}

class KNNavigationController: UINavigationController {
  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}

extension KNBaseViewController {
  @objc open func dismissTutorialOverlayer() {
    if let view = self.tabBarController?.view.viewWithTag(1000) {
      view.removeFromSuperview()
    }
  }

  @objc open func quickTutorialNextAction() {}

  @objc open func quickTutorialContentLabelTapped() {}
}
