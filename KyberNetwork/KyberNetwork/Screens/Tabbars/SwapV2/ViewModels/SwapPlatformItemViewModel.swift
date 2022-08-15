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
  var amountUsdString: String
  var isSelected: Bool = false
  var gasFeeString: String
  var showSavedTag: Bool
  var savedAmountString: String
  var rate: Rate
  
  init(platformRate: Rate, isSelected: Bool, quoteToken: TokenObject, destToken: Token, destTokenPrice: Double, gasFeeUsd: BigInt, showSaveTag: Bool, savedAmount: BigInt) {
    self.rate = platformRate
    self.icon = platformRate.platformIcon
    self.name = platformRate.platformShort
    self.showSavedTag = showSaveTag
    
    self.savedAmountString = String(format: Strings.swapSavedAmount, NumberFormatUtils.amount(value: savedAmount, decimals: 18))
    let receivingAmount = BigInt(platformRate.amount) ?? BigInt(0)
    self.amountString = NumberFormatUtils.amount(value: receivingAmount, decimals: destToken.decimals)
    
    let amountUSD = receivingAmount * BigInt(destTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(destToken.decimals)
    let formattedAmountUSD = NumberFormatUtils.usdAmount(value: amountUSD, decimals: 18)
    self.amountUsdString = "~$\(formattedAmountUSD)"
    
    self.isSelected = isSelected
    self.gasFeeString = String(format: Strings.swapNetworkFee, NumberFormatUtils.gasFee(value: gasFeeUsd))
  }

}
