//
//  SwapPlatformItemViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import BigInt

class SwapPlatformItemViewModel {
  var icon: String
  var name: String
  var amountString: String
  var feeString: String
  var amountUsdString: String
  var isSelected: Bool = false
  
  init(platformRate: Rate, isSelected: Bool, quoteToken: TokenObject) {
    self.icon = platformRate.platformIcon
    self.name = platformRate.platformShort
    self.amountString = (BigInt(platformRate.rate) ?? BigInt(0))?.shortString(decimals: 18) ?? ""
    self.feeString = BigInt(platformRate.estimatedGas).shortString(decimals: quoteToken.decimals)
    self.amountUsdString = ""
    self.isSelected = isSelected
  }
  
}
