//
//  SearchTokenViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 03/08/2022.
//

import UIKit

class SearchTokenViewCell: UITableViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var tagImageView: UIImageView!
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }
  
  func updateUI(token: SwapToken) {
    if let url = URL(string: token.token.logo) {
      self.iconImageView.setImage(with: url, placeholder: UIImage(named: "default_token")!)
    } else {
      self.iconImageView.image = UIImage(named: "default_token")!
    }
    self.symbolLabel.text = token.token.name
    if let balanceBigInt = token.balance.amountBigInt(decimals: 0) {
      self.balanceLabel.text = balanceBigInt.shortString(decimals: token.token.decimals, maxFractionDigits: 6) + " " + token.token.symbol
    } else {
      self.balanceLabel.text = ""
    }
    if let quoteUSD = token.quotes["usd"] {
      self.valueLabel.text = "$" + "\(quoteUSD.value)".displayRate()
    } else {
      self.valueLabel.text = "$0"
    }
    if let tag = token.token.tag {
      self.tagImageView.image = UIImage.imageWithTag(tag: tag)
      self.tagImageView.isHidden = false
    } else {
      self.tagImageView.isHidden = true
    }
    
  }
    
}
