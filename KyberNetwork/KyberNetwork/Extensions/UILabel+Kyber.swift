// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UILabel {
  func addLetterSpacing(value: Double = 0) {
    if let labelText = text, !labelText.isEmpty {
      let attributedString = NSMutableAttributedString(string: labelText)
      attributedString.addAttribute(NSAttributedString.Key.kern, value: value, range: NSRange(location: 0, length: labelText.count))
      attributedText = attributedString
    }
  }
}
