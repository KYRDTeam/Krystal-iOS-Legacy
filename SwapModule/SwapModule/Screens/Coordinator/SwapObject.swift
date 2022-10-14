//
//  SwapObject.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/08/2022.
//

import Foundation
import BigInt
import Services

struct SwapObject {
  var sourceToken: Token
  var destToken: Token
  var sourceAmount: BigInt
  var rate: Rate
  var showRevertedRate: Bool
  var priceImpactState: PriceImpactState
  var sourceTokenPrice: Double
  var destTokenPrice: Double
  var swapSetting: SwapTransactionSettings
}
