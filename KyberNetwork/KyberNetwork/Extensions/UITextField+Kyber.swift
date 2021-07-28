// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UITextField {
  func addPlaceholderSpacing(value: CGFloat = 0.0) {
    let attributedString = NSMutableAttributedString(string: self.placeholder ?? "")
    attributedString.addAttribute(NSAttributedStringKey.kern, value: value, range: NSRange(location: 0, length: (self.placeholder ?? "").count))
    attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(red: 76, green: 102, blue: 112), range: NSRange(location: 0, length: (self.placeholder ?? "").count))
    attributedString.addAttribute(NSAttributedStringKey.font, value: UIFont.Kyber.latoRegular(with: 14), range: NSRange(location: 0, length: (self.placeholder ?? "").count))
    self.attributedPlaceholder = attributedString
  }
}
