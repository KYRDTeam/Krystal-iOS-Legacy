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
  var gasPrice: BigInt
  var gasFeeString: String = ""
  
  init(platformRate: Rate, isSelected: Bool, quoteToken: TokenObject, destToken: TokenObject, gasPrice: BigInt) {
    self.icon = platformRate.platformIcon
    self.name = platformRate.platformShort
    
    let receivingAmount = BigInt(platformRate.amount) ?? BigInt(0)
    self.amountString = NumberFormatUtils.receivingAmount(value: receivingAmount, decimals: destToken.decimals)
    
    let price = KNTrackerRateStorage.shared.getPriceWithAddress(destToken.address)?.usd ?? 0
    let amountUSD = receivingAmount * BigInt(price * pow(10.0, 18.0)) / BigInt(10).power(destToken.decimals)
    let formattedAmountUSD = NumberFormatUtils.receivingAmount(value: amountUSD, decimals: 18)
    self.amountUsdString = "~$\(formattedAmountUSD)"
    
    self.isSelected = isSelected
    self.gasPrice = gasPrice
    self.gasFeeString = self.getMaxGasFee(rate: platformRate, gasPrice: gasPrice)
  }
  
  private func getMaxGasFee(rate: Rate, gasPrice: BigInt) -> String {
    let quoteTokenPrice = KNGeneralProvider.shared.quoteTokenPrice
    let estGas = BigInt(rate.estimatedGas)
    let rateUSDDouble = quoteTokenPrice?.usd ?? 0
    let fee = estGas * gasPrice
    let rateBigInt = BigInt(rateUSDDouble * pow(10.0, 18.0))
    let feeUSD = fee * rateBigInt / BigInt(10).power(18)
    return String(format: Strings.swapNetworkFee, NumberFormatUtils.gasFee(value: feeUSD))
  }

}
