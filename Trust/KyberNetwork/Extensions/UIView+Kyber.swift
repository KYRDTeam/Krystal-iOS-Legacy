// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIView {

  func rounded(color: UIColor = .clear, width: CGFloat = 0.0, radius: CGFloat) {
    self.layer.borderColor = color.cgColor
    self.layer.borderWidth = width
    self.layer.cornerRadius = radius
    self.clipsToBounds = true
  }

  func applyHorizontalGradient(with colours: [UIColor]) {
    let gradient = CAGradientLayer.getGradientLayer(
      with: self.bounds,
      colours: colours,
      locations: [0, 1],
      startPoint: CGPoint(x: 0.0, y: 0.5),
      endPoint: CGPoint(x: 1.0, y: 0.5)
    )
    self.layer.insertSublayer(gradient, at: 0)
  }

  func applyVerticalGradient(with colours: [UIColor]) {
    let gradient = CAGradientLayer.getGradientLayer(
      with: self.bounds,
      colours: colours,
      locations: [0, 1],
      startPoint: CGPoint(x: 0.5, y: 0.0),
      endPoint: CGPoint(x: 0.5, y: 1.0)
    )
    self.layer.insertSublayer(gradient, at: 0)
  }

  func applyTopRightBottomLeftGradient(with colours: [UIColor]) {
    let gradient = CAGradientLayer.getGradientLayer(
      with: self.bounds,
      colours: colours,
      locations: [0, 1],
      startPoint: CGPoint(x: 0.0, y: 0.0),
      endPoint: CGPoint(x: 1.0, y: 1.0)
    )
    self.layer.insertSublayer(gradient, at: 0)
  }

  func removeSublayer(at index: Int) {
    guard let layers = self.layer.sublayers, layers.count > index else { return }
    layers[index].removeFromSuperlayer()
  }

  func applyBaseGradientBackground() {
    let colors = [UIColor.Kyber.cyan, UIColor.Kyber.green, UIColor.Kyber.teal]
    self.applyTopRightBottomLeftGradient(with: colors)
  }

  func rotate360Degrees(duration: CFTimeInterval = 1.0, completion: (() -> Void)? = nil) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)

    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    rotateAnimation.fromValue = 0.0
    rotateAnimation.toValue = CGFloat.pi * 2.0
    rotateAnimation.duration = duration

    self.layer.add(rotateAnimation, forKey: nil)
    CATransaction.commit()
  }

  func toImage() -> UIImage? {
    let rect = self.bounds

    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    self.layer.render(in: context!)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}
