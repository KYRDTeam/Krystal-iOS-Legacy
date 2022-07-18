//
//  TxListHeaderCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 12/07/2022.
//

import UIKit

class TxListHeaderCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var totalLabel: UILabel!
  
  func configure(title: String, total: Int) {
    self.titleLabel.text = title
    self.totalLabel.text = "\(total)"
  }
  
}
