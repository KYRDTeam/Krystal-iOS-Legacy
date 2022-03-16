// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

extension UIButton {
  func setBackgroundColor(_ color: UIColor, forState: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, for: forState)
  }
  
  func setImageForAllState(image: UIImage?) {
    self.setImage(image, for: .normal)
    self.setImage(image, for: .highlighted)
  }
  
  func configStarRate(isHighlight: Bool) {
    self.setImageForAllState(image: isHighlight ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"))
  }
}
