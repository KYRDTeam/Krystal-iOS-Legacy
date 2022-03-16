//
//  CryptoFiatCell.swift
//  KyberNetwork
//
//  Created by Com1 on 03/03/2022.
//

import UIKit

class CryptoFiatCell: UITableViewCell {
  static let kCryptoFiatCellID: String = "CryptoFiatCell"
  @IBOutlet weak var icon: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var fullNameLabel: UILabel!
  
  override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
      // Configure the view for the selected state
  }
    
  func updateUI(model: FiatModel) {
    self.nameLabel.text = model.currency
  }
}
