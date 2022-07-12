//
//  MultiSendSubTransactionCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 12/07/2022.
//

import UIKit

class MultiSendSubTransactionCell: UITableViewCell {
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var indexLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  
  func configure(index: Int, address: String, amount: String) {
    indexLabel.text = "\(index + 1)"
    addressLabel.text = address
    amountLabel.text = amount
  }
  
}
