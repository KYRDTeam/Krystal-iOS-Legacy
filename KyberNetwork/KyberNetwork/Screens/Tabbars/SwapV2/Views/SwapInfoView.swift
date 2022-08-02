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
  
  func setTitle(title: String, underlined: Bool) {
    titleLabel.text = title
    let attributedString = NSMutableAttributedString(string: title)
    
//    if underlined {
      let attrs: [NSAttributedString.Key: Any] = [
        .underlineStyle: NSUnderlineStyle.patternDash.rawValue | NSUnderlineStyle.single.rawValue,
        .underlineColor: UIColor.white.withAlphaComponent(0.5)
      ]
      attributedString.addAttributes(attrs, range: NSRange(location: 0, length: attributedString.length))
//    }
    titleLabel.attributedText = attributedString
  }
  
}
