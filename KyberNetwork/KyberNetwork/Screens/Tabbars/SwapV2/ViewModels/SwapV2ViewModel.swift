//
//  SwapV2ViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import BigInt

class SwapV2ViewModel {
  
  private(set) var selectedPlatform: String?
  
  var currentChain: ChainType {
    return KNGeneralProvider.shared.currentChain
  }
  
  var sortedRates: [Rate] = [] {
    didSet {
      guard let destToken = self.destToken.value else {
        self.platformRatesViewModels.value = []
        return
      }
      var savedAmount: BigInt = 0
      if sortedRates.count >= 2 {
        let diffAmount = (BigInt(platformRates[0].amount) ?? BigInt(0)) - (BigInt(platformRates[1].amount) ?? BigInt(0))
        let diffFee = BigInt(platformRates[0].estimatedGas) - BigInt(platformRates[1].estimatedGas)
        let destTokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(destToken.address)?.usd ?? 0
        let diffAmountUSD = diffAmount * BigInt(destTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(destToken.decimals)
        let diffFeeUSD = diffFee * self.getGasFeeUSD(estGas: diffFee, gasPrice: self.gasPrice)
        savedAmount = diffAmountUSD - diffFeeUSD
      }
      self.platformRatesViewModels.value = sortedRates.enumerated().map { index, rate in
        return SwapPlatformItemViewModel(platformRate: rate,
                                         isSelected: rate.platform == selectedPlatform,
                                         quoteToken: currentChain.quoteTokenObject(),
                                         destToken: destToken,
                                         gasFeeUsd: self.getGasFeeUSD(estGas: BigInt(rate.estimatedGas), gasPrice: self.gasPrice),
                                         showSaveTag: sortedRates.count > 1 && index == 0 /* && savedAmount > BigInt(0.1 * pow(10.0, 18.0))*/,
                                         savedAmount: savedAmount)
      }
    }
  }
  
  private var platformRates: [Rate] = [] {
    didSet {
      self.selectedPlatform = platformRates.isEmpty ? nil : platformRates.first?.platform
      self.sortedRates = self.sortedRates(rates: platformRates)
    }
  }
  
  static let mockSourceToken = ChainType.bsc.quoteTokenObject()
  static let mockDestToken = TokenObject(name: "BUSD", symbol: "BUSD", address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", decimals: 18, logo: "")
  
  var sourceToken: Observable<TokenObject?> = .init(SwapV2ViewModel.mockSourceToken) {
    didSet {
      self.reloadRates()
    }
  }
  
  var destToken: Observable<TokenObject?> = .init(SwapV2ViewModel.mockDestToken) {
    didSet {
      self.reloadRates()
    }
  }
  
  var sourceAmountValue: Double = 0 {
    didSet {
      guard let srcToken = sourceToken.value else {
        self.sourceAmount = nil
        return
      }
      self.sourceAmount = BigInt(sourceAmountValue * pow(10.0, Double(srcToken.decimals)))
    }
  }
  
  var sourceAmount: BigInt? = nil {
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
    guard let sourceToken = sourceToken.value, let destToken = destToken.value, let sourceAmount = sourceAmount else {
      self.platformRates = []
      return
    }
    rateService.getAllRates(address: address, srcTokenContract: sourceToken.address, destTokenContract: destToken.address,
                            amount: sourceAmount, focusSrc: true) { rates in
      self.platformRates = rates
    }
  }
  
  func selectPlatform(platform: String) {
    self.selectedPlatform = platform
    self.sortedRates = self.sortedRates(rates: platformRates)
  }
  
  private func sortedRates(rates: [Rate]) -> [Rate] {
    let sortedRates = rates.sorted { lhs, rhs in
      return BigInt.bigIntFromString(value: lhs.rate) > BigInt.bigIntFromString(value: rhs.rate)
    }
    if sortedRates.isEmpty {
      return []
    }
    return [sortedRates.first!] + sortedRates.dropFirst().sorted { lhs, rhs in
      if lhs.platform == selectedPlatform {
        return true
      }
      return BigInt.bigIntFromString(value: lhs.rate) > BigInt.bigIntFromString(value: rhs.rate)
    }
  }
  
  private func getGasFeeUSD(estGas: BigInt, gasPrice: BigInt) -> BigInt {
    let quoteTokenPrice = KNGeneralProvider.shared.quoteTokenPrice
    let rateUSDDouble = quoteTokenPrice?.usd ?? 0
    let fee = estGas * gasPrice
    let rateBigInt = BigInt(rateUSDDouble * pow(10.0, 18.0))
    let feeUSD = fee * rateBigInt / BigInt(10).power(18)
    return feeUSD
  }
  
}
