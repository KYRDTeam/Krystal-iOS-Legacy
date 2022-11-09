//
//  SwapInfoView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import UIKit
import Utilities

@IBDesignable
public class SwapInfoView: BaseXibView {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var leftValueIcon: UIImageView!
  @IBOutlet weak var underlineView: DashedLineView!
  
  var isTitleUnderlined: Bool = false {
    didSet {
      setNeedsLayout()
    }
  }
  
  @IBInspectable var valueAccessibilityID: String? {
    didSet {
      valueLabel.accessibilityID = valueAccessibilityID
    }
  }
  
  public var onTapRightIcon: (() -> ())?
  public var onTapTitle: (() -> ())?
  public var onTapValue: (() -> ())?
  
  public override func commonInit() {
    super.commonInit()
    
    leftValueIcon.isHidden = true
    
    iconImageView.isUserInteractionEnabled = true
    iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rightIconWasTapped)))
    
    titleLabel.isUserInteractionEnabled = true
    titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleWasTapped)))
    
    valueLabel.isUserInteractionEnabled = true
    valueLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(valueWasTapped)))
  }
  
  @objc func rightIconWasTapped() {
    onTapRightIcon?()
  }
  
  @objc func titleWasTapped() {
    onTapTitle?()
  }
  
  @objc func valueWasTapped() {
    onTapValue?()
  }
    
    public func setInfo(title: String, value: String, shouldShowIcon: Bool = false) {
        titleLabel.text = title
        valueLabel.text = value
        iconImageView.isHidden = !shouldShowIcon
    }
  
  public func setTitle(title: String, underlined: Bool, shouldShowIcon: Bool = false) {
    titleLabel.text = title
    underlineView.isHidden = !underlined
    iconImageView.isHidden = !shouldShowIcon
  }
  
  public func setValue(value: String?, highlighted: Bool = false) {
    valueLabel.text = value
    valueLabel.textColor = highlighted ? AppTheme.current.primaryColor : AppTheme.current.secondaryTextColor
    valueLabel.font = highlighted ? UIFont.karlaMedium(ofSize: 14) : UIFont.karlaReguler(ofSize: 14)
  }
  
  public func setLeftValueIcon(icon: String, isHidden: Bool) {
    leftValueIcon.isHidden = isHidden
    leftValueIcon.loadImage(icon)
  }
  
}
