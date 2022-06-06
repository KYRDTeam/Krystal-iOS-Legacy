//
//  BridgeTxFeeCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/05/2022.
//

import UIKit
import BigInt

class TxInfoCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var helpIcon: UIImageView!
  
  func configure(title: String, value: String, showHelpIcon: Bool = false) {
    titleLabel.text = title
    valueLabel.text = value
    helpIcon.isHidden = !showHelpIcon
  }
}
