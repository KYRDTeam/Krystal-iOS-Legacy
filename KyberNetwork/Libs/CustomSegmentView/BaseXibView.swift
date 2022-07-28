//
//  BaseXibView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 18/07/2022.
//

import UIKit

class BaseXibView: UIView {
  var contentView: UIView!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  func commonInit() {
    contentView = loadViewFromNib()
    contentView.frame = bounds
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentView.translatesAutoresizingMaskIntoConstraints = true
    addSubview(contentView)
    backgroundColor = .clear
  }
  
  private func loadViewFromNib() -> UIView {
    let bundle = Bundle(for: type(of: self))
    let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
    let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView
    return nibView
  }
  
  override open func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    commonInit()
    invalidateIntrinsicContentSize()
  }
}
