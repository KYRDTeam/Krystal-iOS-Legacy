//
//  SwapV2ViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import BigInt

class SwapV2ViewModel {
  
  private var platformRates: [Rate] = [] {
    didSet {
      self.platformRatesViewModels.value = platformRates.map { rate in
        return SwapPlatformItemViewModel(platformRate: rate)
      }
    }
  }
  
  var sourceToken: String? = "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82" {
    didSet {
      self.reloadRates()
    }
  }
  
  var destToken: String? = "0xe9e7cea3dedca5984780bafc599bd69add087d56" {
    didSet {
      self.reloadRates()
    }
  }
  
  var amount: BigInt? = BigInt(100000000000) {
    didSet {
      self.reloadRates()
    }
  }
  
  var address: String {
    return AppDelegate.session.address.addressString
  }
  
  var numberOfRateRows: Int {
    return platformRatesViewModels.value.count
  }
  
  public private(set) var platformRatesViewModels: Observable<[SwapPlatformItemViewModel]> = .init([])
  
  private let rateService = SwapRateService()

  
  init() {
    self.reloadRates()
  }
  
  func reloadRates() {
    guard let sourceToken = sourceToken, let destToken = destToken, let amount = amount else { return }
    rateService.getAllRates(address: address, srcTokenContract: sourceToken, destTokenContract: destToken,
                            amount: amount, focusSrc: true) { rates in
      self.platformRates = rates
    }
  }
  
}
