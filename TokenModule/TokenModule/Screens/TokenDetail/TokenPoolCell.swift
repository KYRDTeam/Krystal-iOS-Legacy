//
//  TokenPoolCell.swift
//  KyberNetwork
//
//  Created by Com1 on 20/06/2022.
//

import UIKit
import Services
import BaseWallet
import Utilities
import DesignSystem
import AppState

class TokenPoolCell: UITableViewCell {
  @IBOutlet weak var token0Icon: UIImageView!
  @IBOutlet weak var token1Icon: UIImageView!
  @IBOutlet weak var pairNameLabel: UILabel!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!

  @IBOutlet weak var pairNameLabelWidth: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  
  func updateUI(isSelecting: Bool, chain: ChainType, poolDetail: TokenPoolDetail, baseTokenAddress: String, currencyMode: CurrencyMode) {
    containerView.backgroundColor = isSelecting ? AppTheme.current.primaryColor.withAlphaComponent(0.2) : AppTheme.current.sectionBackgroundColor
    
    var baseToken = poolDetail.token0
    var otherToken = poolDetail.token1
    
    if poolDetail.token1.address.lowercased() == baseTokenAddress.lowercased() {
      baseToken = poolDetail.token1
      otherToken = poolDetail.token0
    }

    token0Icon.loadImage(baseToken.logo)
    token1Icon.loadImage(otherToken.logo)

    self.pairNameLabel.text = "\(baseToken.symbol)/\(otherToken.symbol)"
    self.pairNameLabelWidth.constant = "\(baseToken.symbol)/\(otherToken.symbol)".width(withConstrainedHeight: 21, font: UIFont.karlaReguler(ofSize: 18))
    self.fullNameLabel.text = poolDetail.name
    self.chainIcon.image = ChainType.make(chainID: poolDetail.chainId)?.chainIcon()
    self.addressLabel.text = poolDetail.address.shortTypeAddress
    
    let totalValueString = currencyMode.symbol() + NumberFormatUtils.volFormat(number: poolDetail.tvl) + currencyMode.suffixSymbol(chain: chain)
    self.totalValueLabel.text = totalValueString
  }
}
