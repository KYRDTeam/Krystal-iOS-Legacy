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
      self.selectedPlatformRate.value = platformRates.value.first(where: { rate in
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
        return self.calculateEstimatedGasFeeString(rate: $0)
      }
      self.priceImpactString.value = self.selectedPlatformRate.value.map {
        if refPrice == 0 {
          self.priceImpactState.value = .normal
          return "0%"
        }
        let rateDouble = Double(BigInt($0.rate) ?? .zero) / pow(10.0, 18)
        let change = (rateDouble - refPrice) / refPrice * 100
        self.priceImpactState.value = self.getPriceImpactState(change: change)
        return "\(String(format: "%.2f", change))%"
      }
    }
  }
  
  var sortedRates: [Rate] = [] {
    didSet {
      guard let destToken = self.destToken.value else {
        self.platformRatesViewModels.value = []
        return
      }
      self.platformRatesViewModels.value = createPlatformRatesViewModels(destToken: destToken, sortedRates: sortedRates)
    }
  }
  
  static let mockSourceToken = ChainType.bsc.quoteTokenObject()
  static let mockDestToken = TokenObject(name: "BUSD", symbol: "BUSD", address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", decimals: 18, logo: "")
  
  var sourceAmountValue: Double? {
    didSet {
      guard let srcToken = sourceToken.value else {
        self.sourceAmount.value = nil
        return
      }
      self.sourceAmount.value = BigInt((sourceAmountValue ?? 0) * pow(10.0, Double(srcToken.decimals)))
    }
  }
  
  var isInputValid: Bool {
    return sourceToken.value != nil && destToken.value != nil && (sourceAmountValue ?? 0) > 0
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
  var selectedPlatformRate: Observable<Rate?> = .init(nil)
  var sourceAmount: Observable<BigInt?> = .init(nil)
  var platformRates: Observable<[Rate]> = .init([])
  
  var rateString: Observable<String?> = .init(nil)
  var slippageString: Observable<String?> = .init(nil)
  var minReceiveString: Observable<String?> = .init(nil)
  var estimatedGasFeeString: Observable<String?> = .init(nil)
  var maxGasFeeString: Observable<String?> = .init(nil)
  var priceImpactString: Observable<String?> = .init(nil)
  var routeString: Observable<String?> = .init(nil)
  var priceImpactState: Observable<PriceImpactState> = .init(.normal)
  
  var state: Observable<SwapState> = .init(.emptyAmount)
  
  private let swapRepository = SwapRepository()

  init() {
    // Initialize values
    minRatePercent = 0.5
    slippageString.value = "\(String(format: "%.1f", self.minRatePercent))%"
    
    self.selfObserve()
    self.reloadSourceBalance()
    self.reloadDestBalance()
  }
  
  func selfObserve() {
    sourceAmount.observeAndFire(on: self) { [weak self] amount in
      guard let self = self else { return }
      if amount == nil || amount!.isZero {
        self.state.value = .emptyAmount
      } else if amount! > (self.sourceBalance.value ?? .zero) {
        self.state.value = .insufficientBalance
      } else {
        self.reloadRates(amount: amount!, withFetchingRefPrice: true)
      }
    }
    platformRates.observe(on: self) { [weak self] rates in
      guard let self = self else { return }
      self.selectedPlatformName = rates.first?.platform
      self.sortedRates = self.sortedRates(rates: rates)
      if rates.isEmpty {
        self.state.value = .rateNotFound
      } else {
        self.state.value = .checkingAllowance
        self.checkAllowance()
      }
    }
  }
  
  func checkAllowance() {
    swapRepository.getAllowance(tokenAddress: sourceToken.value?.address ?? "", address: address) { [weak self] allowance, _ in
      guard let self = self else { return }
      if allowance < self.sourceAmount.value ?? .zero {
        self.state.value = .notApproved
      } else {
        self.state.value = .ready
      }
    }
  }
  
  func reloadRefPrice() {
    guard let sourceToken = sourceToken.value, let destToken = destToken.value else {
      self.refPrice = 0
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
  
  func reloadRates(amount: BigInt, withFetchingRefPrice: Bool) {
    self.selectedPlatformName = nil
    guard let sourceToken = sourceToken.value, let destToken = destToken.value else {
      return
    }
    self.state.value = .fetchingRates
    
    if withFetchingRefPrice {
      swapRepository.getRefPrice(sourceToken: sourceToken.address, destToken: destToken.address) { [weak self] change in
        guard let self = self else { return }
        guard let change = change else {
          self.refPrice = 0
          return
        }
        self.refPrice = Double(change) ?? 0
        self.swapRepository.getAllRates(address: self.address, srcTokenContract: sourceToken.address, destTokenContract: destToken.address, amount: amount, focusSrc: true) { rates in
          self.platformRates.value = rates
        }
      }
    } else {
      self.swapRepository.getAllRates(address: address, srcTokenContract: sourceToken.address, destTokenContract: destToken.address, amount: amount, focusSrc: true) { [weak self] rates in
        self?.platformRates.value = rates
      }
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
    self.sortedRates = self.sortedRates(rates: platformRates.value)
  }
  
  func swapPair() {
    (sourceToken.value, destToken.value) = (destToken.value, sourceToken.value)
    self.sourceAmountValue = nil
    self.selectedPlatformName = nil
    self.reloadSourceBalance()
    self.reloadDestBalance()
  }
  
  func reloadRates() {
    guard state.value.isActiveState else {
      return
    }
    guard let amount = self.sourceAmount.value, !amount.isZero else {
      return
    }
    reloadRates(amount: amount, withFetchingRefPrice: false)
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
  
  private func calculateEstimatedGasFeeString(rate: Rate) -> String {
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
        return "advanced".toBeLocalised()
      }
    }()
    return "$\(gasFeeUSDString) • \(typeString)"
  }
  
  private func createPlatformRatesViewModels(destToken: TokenObject, sortedRates: [Rate]) -> [SwapPlatformItemViewModel] {
    var savedAmount: BigInt = 0
    if sortedRates.count >= 2 {
      let diffAmount = (BigInt(sortedRates[0].amount) ?? BigInt(0)) - (BigInt(sortedRates[1].amount) ?? BigInt(0))
      let diffFee = BigInt(sortedRates[0].estimatedGas) - BigInt(sortedRates[1].estimatedGas)
      let destTokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(destToken.address)?.usd ?? 0
      let diffAmountUSD = diffAmount * BigInt(destTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(destToken.decimals)
      let diffFeeUSD = diffFee * self.getGasFeeUSD(estGas: diffFee, gasPrice: self.gasPrice)
      savedAmount = diffAmountUSD - diffFeeUSD
    }
    return sortedRates.enumerated().map { index, rate in
      return SwapPlatformItemViewModel(platformRate: rate,
                                       isSelected: rate.platform == selectedPlatformName,
                                       quoteToken: currentChain.quoteTokenObject(),
                                       destToken: destToken,
                                       gasFeeUsd: self.getGasFeeUSD(estGas: BigInt(rate.estimatedGas), gasPrice: self.gasPrice),
                                       showSaveTag: sortedRates.count > 1 && index == 0 && savedAmount > BigInt(0.1 * pow(10.0, 18.0)),
                                       savedAmount: savedAmount)
    }
  }
  
  private func getPriceImpactState(change: Double) -> PriceImpactState {
    if 0 <= change && change < 5 {
      return .normal
    }
    if 5 <= change && change < 15 {
      return .high
    }
    return .veryHigh
  }
  
}
