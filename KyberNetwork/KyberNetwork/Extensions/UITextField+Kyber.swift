// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UITextField {
  func addPlaceholderSpacing(value: CGFloat = 0.0) {
    let attributedString = NSMutableAttributedString(string: self.placeholder ?? "")
    attributedString.addAttribute(NSAttributedString.Key.kern, value: value, range: NSRange(location: 0, length: (self.placeholder ?? "").count))
    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 76, green: 102, blue: 112), range: NSRange(location: 0, length: (self.placeholder ?? "").count))
    attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.Kyber.latoRegular(with: 14), range: NSRange(location: 0, length: (self.placeholder ?? "").count))
    self.attributedPlaceholder = attributedString
  }
  
  func setPlaceholder (text: String, color: UIColor) {
    self.attributedPlaceholder = NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: color])
  }
  
  func setupCustomDeleteIcon() {
    if let clearButton = self.value(forKeyPath: "_clearButton") as? UIButton {
      clearButton.setImage(UIImage(named: "delete_textfield_icon"), for: .normal)
    }
  }
}
