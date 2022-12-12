//
//  NavigationBar.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import UIKit
import Utilities

class NavigationBar: UIView {
  
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var leftButton: UIButton!
  @IBOutlet weak var rightButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var badgeView: UIView!
  
  @IBInspectable var title: String? {
    didSet { titleLabel.text = title }
  }
  
  @IBInspectable var leftButtonIcon: UIImage? {
    didSet {
      leftButton.setImage(leftButtonIcon, for: .normal)
    }
  }
  
  override init(frame: CGRect) {
      super.init(frame: frame)
      self.commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      self.commonInit()
  }
  
  var heightView: CGFloat = 52.0
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: frame.width, height: heightView)
  }
  
  private var leftButtonAction: (() -> ())? {
    didSet {
      if let action = leftButtonAction {
        leftButton.addAction(for: .touchUpInside, action: action)
      }
    }
  }
  
  func setLeftButtonAction(_ action: (() -> ())?) {
    if let _ = leftButtonAction { return }
    leftButtonAction = action
  }
  
  @IBInspectable var rightButtonImage: UIImage? {
    didSet {
      rightButton.setImage(rightButtonImage, for: .normal)
    }
  }
  
  private var rightButtonAction: (() -> ())? {
    didSet {
      if let action = rightButtonAction {
        rightButton.addAction(for: .touchUpInside, action: action)
      }
    }
  }
  
  func setRightButtonAction(_ action: (() -> ())?) {
    if let _ = rightButtonAction { return }
    rightButtonAction = action
  }
  
  func prepareNib() {
    let bundle = Bundle(for: NavigationBar.self)
    bundle.loadNibNamed(String(describing: NavigationBar.self), owner: self, options: nil)
  }
  
  func commonInit() {
    prepareNib()
    addSubview(contentView)
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    
    titleLabel.text = title
    leftButton.setImage(leftButtonIcon, for: .normal)
    rightButton.setImage(rightButtonImage, for: .normal)
    
    if let action = leftButtonAction {
        leftButton.addAction(for: .touchUpInside, action: action)
    }
    if let action = rightButtonAction {
      rightButton.addAction(for: .touchUpInside, action: action)
    }
  }
  
  override open func prepareForInterfaceBuilder() {
      super.prepareForInterfaceBuilder()
      commonInit()
      invalidateIntrinsicContentSize()
      
  }
}
