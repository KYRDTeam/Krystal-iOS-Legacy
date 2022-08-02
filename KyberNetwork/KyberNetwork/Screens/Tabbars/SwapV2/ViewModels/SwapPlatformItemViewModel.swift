//
//  SwapPlatformItemViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation

class SwapPlatformItemViewModel {
  var icon: String
  var name: String
  var amountString: String
  var feeString: String
  var feeUsdString: String
  
  init(platformRate: PlatformRate) {
    self.icon = platformRate.platformIcon
    self.name = platformRate.platform
    self.amountString = platformRate.rate
    self.feeString = ""
    self.feeUsdString = ""
  }
  
}
