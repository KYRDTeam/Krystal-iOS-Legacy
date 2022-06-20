//
//  AdvanceSearchTokenCell.swift
//  KyberNetwork
//
//  Created by Com1 on 14/06/2022.
//

import UIKit

class AdvanceSearchTokenCell: UITableViewCell {
  @IBOutlet weak var tokenIcon: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tagIcon: UIImageView!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!
  @IBOutlet weak var fullNameLabelLeadingConstraint: NSLayoutConstraint!
  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  func updateUI(token: ResultToken?) {
    guard let token = token else {
      return
    }
    tokenIcon.setSymbolImage(symbol: token.symbol)
    if let image = UIImage.imageWithTag(tag: token.tag) {
      tagIcon.image = image
      self.fullNameLabelLeadingConstraint.constant = 30
    } else {
      self.fullNameLabelLeadingConstraint.constant = 10
    }
    tokenNameLabel.text = token.symbol
    fullNameLabel.text = token.name
    priceLabel.text = StringFormatter.usdString(value: token.usdValue)
    if let chainType = ChainType.make(chainID: token.chainId) {
      chainIcon.image = chainType.chainIcon()
    }
    addressLabel.text = token.id
  }
  
  func updateUI(poolData: TokenPoolDetail) {
    
  }
    
}
