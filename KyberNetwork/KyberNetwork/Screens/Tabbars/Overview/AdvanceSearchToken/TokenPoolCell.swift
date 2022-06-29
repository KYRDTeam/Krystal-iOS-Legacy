//
//  TokenPoolCell.swift
//  KyberNetwork
//
//  Created by Com1 on 20/06/2022.
//

import UIKit

class TokenPoolCell: UITableViewCell {

  @IBOutlet weak var token0Icon: UIImageView!
  @IBOutlet weak var token1Icon: UIImageView!
  @IBOutlet weak var pairNameLabel: UILabel!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!

  @IBOutlet weak var pairNameLabelWidth: NSLayoutConstraint!
  @IBOutlet weak var valueLabelWidth: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  
  func updateUI(isSelecting: Bool, poolDetail: TokenPoolDetail, baseTokenAddress: String, currencyMode: CurrencyMode) {
    containerView.backgroundColor = isSelecting ? UIColor.Kyber.primaryGreenColor.withAlphaComponent(0.2) : UIColor.Kyber.cellBackground
    
    var baseToken = poolDetail.token0
    var otherToken = poolDetail.token1
    
    if poolDetail.token1.address.lowercased() == baseTokenAddress.lowercased() {
      baseToken = poolDetail.token1
      otherToken = poolDetail.token0
    }

    if let url = URL(string: baseToken.logo) {
      token0Icon.setImage(with: url, placeholder: nil)
    }
    if let url = URL(string: otherToken.logo) {
      token1Icon.setImage(with: url, placeholder: nil)
    }

    self.pairNameLabel.text = "\(baseToken.symbol)/\(otherToken.symbol)"
    self.pairNameLabelWidth.constant = "\(baseToken.symbol)/\(otherToken.symbol)".width(withConstrainedHeight: 21, font: UIFont.Kyber.regular(with: 18))
    self.fullNameLabel.text = poolDetail.name
    self.valueLabel.text = "$\(String.formatBigNumberCurrency(baseToken.usdValue))"
    self.valueLabelWidth.constant = "$\(baseToken.usdValue)".width(withConstrainedHeight: 21, font: UIFont.Kyber.regular(with: 16))
    self.chainIcon.image = ChainType.make(chainID: poolDetail.chainId)?.chainIcon()
    self.addressLabel.text = "\(poolDetail.address.prefix(7))...\(poolDetail.address.suffix(4))"
    
    let totalValueString = currencyMode.symbol() + "\(String.formatBigNumberCurrency(poolDetail.tvl))" + currencyMode.suffixSymbol()
    self.totalValueLabel.text = totalValueString
  }
}
