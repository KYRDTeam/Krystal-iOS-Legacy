//
//  TransitionDelegate.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/13/20.
//

import Foundation
import UIKit

public protocol BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat)
  func getPopupHeight() -> CGFloat
  func getPopupContentView() -> UIView
}

class TransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
  
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return PresentAnimator()
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return DismissAnimator()
  }
  
  func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    return nil
  }
}


class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  // MARK: - Properties
  private var transitionDriver: PresentTransitionDriver?
  
  // MARK: - Methods
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.3
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    transitionDriver = PresentTransitionDriver(transitionContext: transitionContext)
    interruptibleAnimator(using: transitionContext).startAnimation()
  }
  
  func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
    return transitionDriver!.animator!
  }
  
  func animationEnded(_ transitionCompleted: Bool) {
    transitionDriver = nil
  }
}

class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  // MARK: - Properties
  private var transitionDriver: DismissTransitionDriver?
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.3
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    transitionDriver = DismissTransitionDriver(transitionContext: transitionContext)
    interruptibleAnimator(using: transitionContext).startAnimation()
  }
  
  func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
    return transitionDriver!.animator!
  }
  
  func animationEnded(_ transitionCompleted: Bool) {
    transitionDriver = nil
  }
}

class PresentTransitionDriver {
  
  // MARK: - Properties
  var animator: UIViewPropertyAnimator?
  private let ctx: UIViewControllerContextTransitioning
  private let container: UIView
  private let fromVC: UIViewController
  private let toVC: UIViewController
  private let fromView: UIView
  private let toView: UIView
  private let secondaryView: BottomPopUpAbstract
  
  // MARK: - Lifecycle
  init(transitionContext: UIViewControllerContextTransitioning) {
    ctx = transitionContext
    container = transitionContext.containerView
    fromVC = transitionContext.viewController(forKey: .from)!
    toVC = transitionContext.viewController(forKey: .to)!
    fromView = fromVC.view!
    toView = toVC.view!
    secondaryView = toVC as! BottomPopUpAbstract

    createAnimator()
  }
  
  // MARK: - Methods
  private func createAnimator() {
    /// Preparing
    container.addSubview(toView)
    toView.translatesAutoresizingMaskIntoConstraints = false
    toView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
    toView.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
    toView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
    toView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
    container.layoutIfNeeded()

    secondaryView.setTopContrainConstant(value: UIScreen.main.bounds.size.height)
    toView.layoutIfNeeded()
    
    /// Animation
    animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) { [weak self] in
      self?.stretchFromBottom()
      self?.roundCorners()
    }
    animator?.startAnimation()
    
    animator?.addCompletion { [weak self] _ in
      self?.completeAnimation()
    }
  }
  
  private func stretchFromBottom() {
    secondaryView.setTopContrainConstant(value: UIScreen.main.bounds.size.height - secondaryView.getPopupHeight())
    toView.layoutIfNeeded()
  }
  
  private func roundCorners() {
    secondaryView.getPopupContentView().layer.cornerRadius = 20
  }
  
  private func completeAnimation() {
    let success = !ctx.transitionWasCancelled
    ctx.completeTransition(success)
  }
}

class DismissTransitionDriver {
  
  // MARK: - Properties
  var animator: UIViewPropertyAnimator?
  private let ctx: UIViewControllerContextTransitioning
  private let fromVC: UIViewController
  private let toVC: UIViewController
  private let fromView: UIView
  private let toView: UIView
  private let secondaryView: BottomPopUpAbstract
  
  // MARK: - Lifecycle
  init(transitionContext: UIViewControllerContextTransitioning) {
    ctx = transitionContext
    fromVC = transitionContext.viewController(forKey: .from)!
    toVC = transitionContext.viewController(forKey: .to)!
    fromView = fromVC.view!
    toView = toVC.view!
    secondaryView = fromVC as! BottomPopUpAbstract

    createAnimator()
  }

  // MARK: - Methods
  private func createAnimator() {
    
    /// Animation
    animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) { [weak self] in
      self?.secondaryView.setTopContrainConstant(value: UIScreen.main.bounds.size.height)
      self?.fromView.layoutIfNeeded()
    }
    animator?.startAnimation()
    animator?.addCompletion { [weak self] _ in
      self?.completeAnimation()
    }
  }
  
  private func completeAnimation() {
    let success = !ctx.transitionWasCancelled
    ctx.completeTransition(success)
  }
}
