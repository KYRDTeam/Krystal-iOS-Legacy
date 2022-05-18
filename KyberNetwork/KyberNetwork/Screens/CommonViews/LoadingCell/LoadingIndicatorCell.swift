//
//  LoadingIndicatorCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/04/2022.
//

import UIKit

class LoadingIndicatorCell: UICollectionViewCell {
  
  var inidicator: UIActivityIndicatorView = {
    let view = UIActivityIndicatorView(style: .gray)
    view.color = .white.withAlphaComponent(0.8)
    return view
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  func setup() {
    inidicator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(inidicator)
    inidicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
    inidicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    inidicator.startAnimating()
  }
  
}
