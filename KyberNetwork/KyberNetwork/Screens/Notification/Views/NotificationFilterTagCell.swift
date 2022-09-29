//
//  NotificationFilterTagCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import UIKit

class NotificationFilterTagCell: UICollectionViewCell {
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!

  func configure(title: String, isSelecting: Bool) {
    titleLabel.text = title
    titleLabel.textColor = isSelecting ? .Kyber.buttonText : .Kyber.inactiveButtonText
    containerView.backgroundColor = isSelecting ? .Kyber.buttonBg : .Kyber.cellBackground
  }
  
}
