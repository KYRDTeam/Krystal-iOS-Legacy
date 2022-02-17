//
//  MultiSendAddressCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/02/2022.
//

import UIKit

struct MultiSendAddressCellModel {
  let item: MultiSendItem
  let index: Int
  
  var displayAmt: String {
    let amtStr = self.item.1.string(
      decimals: self.item.2.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.item.2.decimals, 5)
    )
    
    return "\(amtStr) \(item.2.symbol)"
  }
}

class MultiSendAddressCell: UITableViewCell {
  
  static let cellHeight: CGFloat = 42
  static let cellID: String = "MultiSendAddressCell"
  
  @IBOutlet weak var indexLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  
  var cellModel: MultiSendAddressCellModel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateCellModel(_ model: MultiSendAddressCellModel) {
    self.indexLabel.text = "\(model.index)"
    self.addressLabel.text = model.item.0
    self.amountLabel.text = model.displayAmt
    self.cellModel = model
  }
  
}
