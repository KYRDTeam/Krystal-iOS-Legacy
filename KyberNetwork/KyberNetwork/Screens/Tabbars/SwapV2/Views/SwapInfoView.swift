//
//  SwapInfoView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import UIKit

class SwapInfoView: BaseXibView {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  
  var isTitleUnderlined: Bool = false {
    didSet {
      setNeedsLayout()
    }
  }
  
  var onTapRightIcon: (() -> ())?
  var onTapTitle: (() -> ())?
  
  override func commonInit() {
    super.commonInit()
    
  }
  
  func setTitle(title: String, underlined: Bool, shouldShowIcon: Bool = false) {
    titleLabel.text = title
    let attributedString = NSMutableAttributedString(string: title)
    
    if underlined {
      let attrs: [NSAttributedString.Key: Any] = [
        .underlineStyle: NSUnderlineStyle.patternDash.rawValue | NSUnderlineStyle.thick.rawValue,
        .underlineColor: UIColor.white.withAlphaComponent(0.5)
      ]
      attributedString.addAttributes(attrs, range: NSRange(location: 0, length: attributedString.length))
    }
    titleLabel.attributedText = attributedString
    iconImageView.isHidden = !shouldShowIcon
  }
  
  func setValue(value: String?, highlighted: Bool = false) {
    valueLabel.text = value
    valueLabel.textColor = highlighted ? .Kyber.primaryGreenColor : .white.withAlphaComponent(0.5)
    valueLabel.font = highlighted ? UIFont(name: "Karla-Medium", size: 14) : UIFont(name: "Karla-Regular", size: 14)
  }
  
}
