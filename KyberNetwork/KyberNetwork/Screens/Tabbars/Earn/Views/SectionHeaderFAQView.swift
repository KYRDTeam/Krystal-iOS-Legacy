//
//  SectionHeaderFAQView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 10/11/2022.
//

import Foundation
import UIKit

protocol SectionHeaderFAQViewDelegate: class {
  func didChangeExpandStatus(status: Bool, section: Int)
}

class SectionHeaderFAQView: UITableViewHeaderFooterView {
  let contentLabel = UILabel()
  let expandButton = UIButton()
  
  var isExpand = false {
    didSet {
      if self.isExpand {
        self.expandButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
      } else {
        self.expandButton.transform = CGAffineTransform(rotationAngle: 0)
      }
    }
  }
  weak var delegate: SectionHeaderFAQViewDelegate?
  var section = -1
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    configureContents()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func configureContents() {
    contentLabel.translatesAutoresizingMaskIntoConstraints = false
    expandButton.translatesAutoresizingMaskIntoConstraints = false
    
    expandButton.setImage(UIImage(named: "circle_arrow_up"), for: .normal)
    contentLabel.font = UIFont.Kyber.regular(with: 16)
    contentLabel.textColor = UIColor.Kyber.whiteText
    contentLabel.numberOfLines = 0
    contentView.backgroundColor = UIColor.Kyber.popupBg
    
    expandButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
    
    contentView.addSubview(contentLabel)
    contentView.addSubview(expandButton)
    
    NSLayoutConstraint.activate([
      contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      expandButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      expandButton.widthAnchor.constraint(equalToConstant: 24),
      expandButton.heightAnchor.constraint(equalToConstant: 24),
      expandButton.leadingAnchor.constraint(equalTo: contentLabel.trailingAnchor, constant: 5),
      contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      expandButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    ])
    
    if self.isExpand {
      self.expandButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
    } else {
      self.expandButton.transform = CGAffineTransform(rotationAngle: 0)
    }
  }
  
  func updateTitle(text: String) {
    contentLabel.text = text
  }
  
  @objc func pressed() {
    isExpand = !isExpand
    
    delegate?.didChangeExpandStatus(status: isExpand, section: section)
  }
  
  class func estimateHeightForSection(_ text: String) -> CGFloat {
    let screenWidth = UIScreen.main.bounds.size.width
    let labelWidth  = screenWidth - 70 - 24 - 5
    
    let height = text.height(withConstrainedWidth: labelWidth, font: UIFont.Kyber.regular(with: 16))
    return height + 30
  }
}
