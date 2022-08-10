//
//  SwapSummaryViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 10/08/2022.
//

import UIKit
import Moya
import BigInt

class SwapSummaryViewModel {
  let currentRate: Rate
  let srcToken: Token
  let srcAmount: BigInt
  let destToken: Token
  let destAmount: BigInt
  var rootViewController: SwapSummaryViewController?
  fileprivate var updateRateTimer: Timer?
  
  init(currentRate: Rate, srcToken: Token, srcAmount: BigInt, destToken: Token, destAmout: BigInt) {
    self.currentRate = currentRate
    self.srcToken = srcToken
    self.srcAmount = srcAmount
    self.destToken = destToken
    self.destAmount = destAmout
  }
  
  func startUpdateRate() {
    self.updateRateTimer?.invalidate()
    self.updateRate()
    self.updateRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds15,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.updateRate()
      }
    )
  }
  
  func updateRate() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.requestWithFilter(.getExpectedRate(src: self.srcToken.address.lowercased(), dst: self.destToken.address.lowercased(), srcAmount: self.srcAmount.description, hint: self.currentRate.hint, isCaching: true)) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let rate = json["rate"] as? String {
        if self.currentRate.rate != rate {
          self.rootViewController?.rateUpdated(newRate: rate)
        }
      } else {
        // do nothing in background
      }
    }
  }
}
