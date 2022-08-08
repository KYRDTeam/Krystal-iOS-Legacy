//
//  SwapV2ViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import BigInt

class SwapV2ViewModel {
  
  var selectedRateIndex: Int = 0
  
  var currentChain: ChainType {
    return KNGeneralProvider.shared.currentChain
  }
  
  private var platformRates: [Rate] = [] {
    didSet {
      guard let destToken = self.destToken else {
        self.platformRatesViewModels.value = []
        return
      }
      self.platformRatesViewModels.value = platformRates.enumerated().map { index, rate in
        return SwapPlatformItemViewModel(platformRate: rate,
                                         isSelected: index == selectedRateIndex,
                                         quoteToken: currentChain.quoteTokenObject(),
                                         destToken: destToken,
                                         gasPrice: gasPrice)
      }
    }
  }
  
  static let mockSourceToken = ChainType.bsc.quoteTokenObject()
  static let mockDestToken = TokenObject(name: "BUSD", symbol: "BUSD", address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", decimals: 18, logo: "")
  
  var sourceToken: TokenObject? = SwapV2ViewModel.mockSourceToken {
    didSet {
      self.reloadRates()
    }
  }
  
  var destToken: TokenObject? = SwapV2ViewModel.mockDestToken {
    didSet {
      self.reloadRates()
    }
  }
  
  var amount: BigInt? = BigInt(100000000000000000) {
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
  
  var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  
  private(set) var platformRatesViewModels: Observable<[SwapPlatformItemViewModel]> = .init([])
  
  private let rateService = SwapRateService()

  init() {
    self.reloadRates()
  }
  
  func reloadRates() {
    guard let sourceToken = sourceToken, let destToken = destToken, let amount = amount else { return }
    rateService.getAllRates(address: address, srcTokenContract: sourceToken.address, destTokenContract: destToken.address,
                            amount: amount, focusSrc: true) { rates in
      self.platformRates = rates
    }
  }
  
}
