//
//  SearchTokenViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 03/08/2022.
//

import UIKit
import Services
import Utilities
import ChainModule

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
  
  func updateUI(token: SearchToken) {
    if URL(string: token.token.logo) != nil {
      self.iconImageView.loadImage(token.token.logo)
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
      self.valueLabel.text = "$" + StringFormatter.amountString(value: quoteUSD.value)
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
    
    func configure(item: TokenItemCellViewModel) {
        if item.iconUrl.isEmpty {
            iconImageView.image = UIImage(named: "token", in: Bundle(for: SearchTokenViewCell.self), compatibleWith: nil)
        } else {
            iconImageView.loadImage(item.iconUrl)
        }
        symbolLabel.text = item.name
        balanceLabel.text = item.balanceString
        valueLabel.text = item.balanceValueString
    }
    
    
}
