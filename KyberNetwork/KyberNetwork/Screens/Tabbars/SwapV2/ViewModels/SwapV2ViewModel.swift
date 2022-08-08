//
//  SwapV2ViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import BigInt

class SwapV2ViewModel {
  
  var currentChain: ChainType {
    return KNGeneralProvider.shared.currentChain
  }
  
  private(set) var selectedPlatformName: String? {
    didSet {
      self.selectedPlatformRate.value = platformRates.first(where: { rate in
        rate.platform == selectedPlatformName
      })
      guard let destToken = destToken.value, let sourceToken = sourceToken.value else {
        return
      }
      self.rateString.value = self.selectedPlatformRate.value.map {
        let rateString = NumberFormatUtils.rate(value: BigInt($0.rate) ?? .zero, decimals: destToken.decimals)
        return "1 \(sourceToken.symbol) = \(rateString) \(destToken.symbol)"
      }
      self.minReceiveString.value = self.selectedPlatformRate.value.map {
        let amount = BigInt($0.amount) ?? BigInt(0)
        let minReceivingAmount = amount * BigInt(10000.0 - minRatePercent * 100.0) / BigInt(10000.0)
        return "\(NumberFormatUtils.receivingAmount(value: minReceivingAmount, decimals: destToken.decimals)) \(destToken.symbol)"
      }
      self.estimatedGasFeeString.value = self.selectedPlatformRate.value.map {
        let gasFeeUsd = self.getGasFeeUSD(estGas: BigInt($0.estimatedGas), gasPrice: self.gasPrice)
        return NumberFormatUtils.gasFee(value: gasFeeUsd)
      }
      self.maxGasFeeString.value = self.selectedPlatformRate.value.map {
        return self.calculateMaxGasFeeString(rate: $0)
      }
      self.priceImpactString.value = self.selectedPlatformRate.value.map {
        if refPrice == 0 {
          return "0%"
        }
        let rateDouble = Double(BigInt($0.rate) ?? .zero) / pow(10.0, 18)
        let change = (rateDouble - refPrice) / refPrice * 100
        return "\(String(format: "%.2f", change))%"
      }
    }
  }
  
  var selectedPlatformRate: Observable<Rate?> = .init(nil)
  
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
                                         isSelected: rate.platform == selectedPlatformName,
                                         quoteToken: currentChain.quoteTokenObject(),
                                         destToken: destToken,
                                         gasFeeUsd: self.getGasFeeUSD(estGas: BigInt(rate.estimatedGas), gasPrice: self.gasPrice),
                                         showSaveTag: sortedRates.count > 1 && index == 0 && savedAmount > BigInt(0.1 * pow(10.0, 18.0)),
                                         savedAmount: savedAmount)
      }
    }
  }
  
  private var platformRates: [Rate] = [] {
    didSet {
      self.selectedPlatformName = platformRates.isEmpty ? nil : platformRates.first?.platform
      self.sortedRates = self.sortedRates(rates: platformRates)
    }
  }
  
  static let mockSourceToken = ChainType.bsc.quoteTokenObject()
  static let mockDestToken = TokenObject(name: "BUSD", symbol: "BUSD", address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", decimals: 18, logo: "")
  
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
  
  var isInputValid: Bool {
    return sourceToken.value != nil && destToken.value != nil && sourceAmountValue > 0
  }
  
  var address: String {
    return AppDelegate.session.address.addressString
  }
  
  var numberOfRateRows: Int {
    return platformRatesViewModels.value.count
  }
  
  var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  var refPrice: Double = 0
  
  var selectedGasPriceType: KNSelectedGasPriceType = .medium {
    didSet {
      
    }
  }
  
  var minRatePercent: Double {
    didSet {
      slippageString.value = "\(String(format: "%.1f", self.minRatePercent))%"
    }
  }
  
  var sourceToken: Observable<TokenObject?> = .init(SwapV2ViewModel.mockSourceToken)
  var destToken: Observable<TokenObject?> = .init(SwapV2ViewModel.mockDestToken)
  var platformRatesViewModels: Observable<[SwapPlatformItemViewModel]> = .init([])
  var sourceBalance: Observable<BigInt?> = .init(nil)
  var destBalance: Observable<BigInt?> = .init(nil)
  
  var rateString: Observable<String?> = .init(nil)
  var slippageString: Observable<String?> = .init(nil)
  var minReceiveString: Observable<String?> = .init(nil)
  var estimatedGasFeeString: Observable<String?> = .init(nil)
  var maxGasFeeString: Observable<String?> = .init(nil)
  var priceImpactString: Observable<String?> = .init(nil)
  var routeString: Observable<String?> = .init(nil)
  
  private let swapRepository = SwapRepository()

  init() {
    // Initialize values
    minRatePercent = 0.5
    slippageString.value = "\(String(format: "%.1f", self.minRatePercent))%"
    
    // Fetch data
    self.reloadRates()
    self.reloadSourceBalance()
    self.reloadDestBalance()
    self.reloadPriceImpact()
  }
  
  func reloadPriceImpact() {
    guard let sourceToken = sourceToken.value, let destToken = destToken.value else {
      self.priceImpactString.value = nil
      return
    }
    swapRepository.getRefPrice(sourceToken: sourceToken.address, destToken: destToken.address) { change in
      guard let change = change else {
        self.refPrice = 0
        return
      }
      self.refPrice = Double(change) ?? 0
    }
  }
  
  func reloadRates() {
    self.selectedPlatformName = nil
    guard let sourceToken = sourceToken.value, let destToken = destToken.value, let sourceAmount = sourceAmount else {
      self.platformRates = []
      return
    }
    swapRepository.getAllRates(address: address, srcTokenContract: sourceToken.address, destTokenContract: destToken.address, amount: sourceAmount, focusSrc: true) { rates in
      self.platformRates = rates
    }
  }
  
  func reloadSourceBalance() {
    guard let sourceToken = sourceToken.value else {
      sourceBalance.value = nil
      return
    }
    swapRepository.getBalance(tokenAddress: sourceToken.address, address: address) { [weak self] (amount, tokenAddress) in
      if tokenAddress == sourceToken.address { // Needed to handle case swap pair
        self?.sourceBalance.value = amount
      }
    }
  }
  
  func reloadDestBalance() {
    guard let destToken = destToken.value else {
      destBalance.value = nil
      return
    }
    swapRepository.getBalance(tokenAddress: destToken.address, address: address) { [weak self] (amount, tokenAddress) in
      if tokenAddress == destToken.address { // Needed to handle case swap pair
        self?.destBalance.value = amount
      }
    }
  }
  
  func selectPlatform(platform: String) {
    self.selectedPlatformName = platform
    self.sortedRates = self.sortedRates(rates: platformRates)
  }
  
  func swapPair() {
    (sourceToken.value, destToken.value) = (destToken.value, sourceToken.value)
    self.reloadPriceImpact()
    self.reloadSourceBalance()
    self.reloadDestBalance()
    self.reloadRates()
  }
  
  private func sortedRates(rates: [Rate]) -> [Rate] {
    let sortedRates = rates.sorted { lhs, rhs in
      return BigInt.bigIntFromString(value: lhs.rate) > BigInt.bigIntFromString(value: rhs.rate)
    }
    if sortedRates.isEmpty {
      return []
    }
    return [sortedRates.first!] + sortedRates.dropFirst().sorted { lhs, rhs in
      if lhs.platform == selectedPlatformName {
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
  
  private func calculateMaxGasFeeString(rate: Rate) -> String {
    let gasFeeUSD = self.getGasFeeUSD(estGas: BigInt(rate.estimatedGas), gasPrice: gasPrice)
    let gasFeeUSDString = NumberFormatUtils.gasFee(value: gasFeeUSD)
    let typeString: String = {
      switch self.selectedGasPriceType {
      case .superFast:
        return "super.fast".toBeLocalised()
      case .fast:
        return "fast".toBeLocalised()
      case .medium:
        return "regular".toBeLocalised()
      case .slow:
        return "slow".toBeLocalised()
      case .custom:
        return "advanced"
      }
    }()
    return "$\(gasFeeUSDString) • \(typeString)"
  }
  
}
