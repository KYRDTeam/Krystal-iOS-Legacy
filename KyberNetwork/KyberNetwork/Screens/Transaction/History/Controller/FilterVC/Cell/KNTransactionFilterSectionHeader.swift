//
//  KNTransactionFilterSectionHeader.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/04/2022.
//

import UIKit

class KNTransactionFilterSectionHeader: UICollectionReusableView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var actionButton: UIButton!
  
  var onAction: (() -> ())?
  
  func configure(title: String, actionButtonTitle: String?, action: (() -> ())? = nil) {
    self.titleLabel.text = title
    self.actionButton.setTitle(actionButtonTitle, for: .normal)
    self.onAction = action
  }
  
  @IBAction func actionButtonWasTapped(_ sender: Any) {
    onAction?()
  }
}
