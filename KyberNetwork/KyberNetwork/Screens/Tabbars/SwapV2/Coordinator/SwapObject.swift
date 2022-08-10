//
//  SwapObject.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/08/2022.
//

import Foundation
import BigInt

struct SwapObject {
  var sourceToken: Token
  var destToken: Token
  var sourceAmount: BigInt
  var rate: Rate
  var selectedGasPriceType: KNSelectedGasPriceType
  var gasPrice: BigInt
  var showRevertedRate: Bool
  var minRatePercent: Double
  var refPrice: Double
  var priceImpactState: PriceImpactState
}
