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
  @IBOutlet weak var tokenNameWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var priceConstraint: NSLayoutConstraint!
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  func updateUI(token: ResultToken?, currencyMode: CurrencyMode) {
    guard let token = token else {
      return
    }
    if let logoURL = URL(string: token.logo) {
      tokenIcon.setImage(with: logoURL, placeholder: nil)
    } else {
      tokenIcon.setSymbolImage(symbol: token.symbol)
    }
    
    if let image = UIImage.imageWithTag(tag: token.tag) {
      tagIcon.image = image
      tagIcon.isHidden = false
      self.fullNameLabelLeadingConstraint.constant = 30
    } else {
      tagIcon.isHidden = true
      self.fullNameLabelLeadingConstraint.constant = 10
    }
    tokenNameLabel.text = token.symbol
    tokenNameWidthConstraint.constant = token.symbol.width(withConstrainedHeight: 21, font: UIFont.Kyber.regular(with: 18))
    
    fullNameLabel.text = token.name
    let priceString = token.usdValue == 0 ? "$0" : "$\(token.usdValue)".displayRate()
    priceLabel.text = priceString
    priceConstraint.constant = priceString.width(withConstrainedHeight: 20, font: UIFont.Kyber.regular(with: 16))
    
    if let chainType = ChainType.make(chainID: token.chainId) {
      chainIcon.image = chainType.chainIcon()
    }
    addressLabel.text = "\(token.id.prefix(7))...\(token.id.suffix(4))"
    totalValueLabel.text = currencyMode.symbol() + "\(String.formatBigNumberCurrency(token.tvl))" + currencyMode.suffixSymbol()
  }
}
