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
  
  init(platformRate: Rate) {
    self.icon = platformRate.platformIcon
    self.name = platformRate.platform
    self.amountString = (BigInt(platformRate.rate) ?? BigInt(0))?.shortString(decimals: 18) ?? ""
    self.feeString = ""
    self.amountUsdString = ""
  }
  
}
