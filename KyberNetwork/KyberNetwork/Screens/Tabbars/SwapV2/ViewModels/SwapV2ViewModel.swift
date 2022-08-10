//
//  SwapV2ViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import BigInt
import KrystalWallets

struct SwapV2ViewModelActions {
  var onSelectSwitchChain: () -> ()
  var onSelectSwitchWallet: () -> ()
  var onSelectOpenHistory: () -> ()
  var openSwapConfirm: (SwapObject) -> ()
}

class SwapV2ViewModel {
  
  var actions: SwapV2ViewModelActions
  
  private(set) var selectedPlatformName: String? {
    didSet {
      self.selectedPlatformRate.value = platformRates.value.first(where: { rate in
        rate.platform == selectedPlatformName
      })
      guard let destToken = destToken.value else {
        return
      }
      self.rateString.value = self.getRateString()
      self.minReceiveString.value = self.selectedPlatformRate.value.map {
        let amount = BigInt($0.amount) ?? BigInt(0)
        let minReceivingAmount = amount * BigInt(10000.0 - minRatePercent * 100.0) / BigInt(10000.0)
        return "\(NumberFormatUtils.amount(value: minReceivingAmount, decimals: destToken.decimals)) \(destToken.symbol)"
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
  
  var sourceAmountValue: Double? {
    didSet {
      guard let srcToken = sourceToken.value else {
        self.sourceAmount.value = nil
        return
      }
      self.sourceAmount.value = BigInt((sourceAmountValue ?? 0) * pow(10.0, Double(srcToken.decimals)))
    }
  }
  
  var showRevertedRate: Bool = false {
    didSet {
      self.rateString.value = self.getRateString()
    }
  }
  
  var isInputValid: Bool {
    return sourceToken.value != nil && destToken.value != nil && (sourceAmountValue ?? 0) > 0
  }

  var addressString: String {
    return currentAddress.value.addressString
  }
  
  var numberOfRateRows: Int {
    return platformRatesViewModels.value.count
  }
  
  var gasPrice: BigInt {
    return KNGasCoordinator.shared.defaultKNGas
  }
  
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
  
  var currentAddress: Observable<KAddress> = .init(AppDelegate.session.address)
  var currentChain: Observable<ChainType> = .init(KNGeneralProvider.shared.currentChain)
  var sourceToken: Observable<Token?> = .init(KNGeneralProvider.shared.quoteTokenObject.toData())
  var destToken: Observable<Token?> = .init(nil)
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

  init(actions: SwapV2ViewModelActions) {
    // Initialize values
    minRatePercent = 0.5
    slippageString.value = "\(String(format: "%.1f", self.minRatePercent))%"
    
    self.actions = actions
    self.observeNotifications()
    self.selfObserve()
    self.loadBaseToken()
    self.reloadSourceBalance()
    self.reloadDestBalance()
  }
  
  func loadBaseToken() {
    swapRepository.getCommonBaseTokens { [weak self] tokens in
      self?.destToken.value = tokens.first
      self?.reloadDestBalance()
    }
  }
  
  func selfObserve() {
    sourceAmount.observeAndFire(on: self) { [weak self] amount in
      guard let self = self else { return }
      if amount == nil || amount!.isZero {
        self.selectedPlatformName = nil
        self.state.value = .emptyAmount
      } else if amount! > (self.sourceBalance.value ?? .zero) {
        self.selectedPlatformName = nil
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
  
  func approve() {
    
  }
  
  func checkAllowance() {
    swapRepository.getAllowance(tokenAddress: sourceToken.value?.address ?? "", address: addressString) { [weak self] allowance, _ in
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
        self.swapRepository.getAllRates(address: self.addressString, srcTokenContract: sourceToken.address, destTokenContract: destToken.address, amount: amount, focusSrc: true) { rates in
          self.platformRates.value = rates
        }
      }
    } else {
      self.swapRepository.getAllRates(address: addressString, srcTokenContract: sourceToken.address, destTokenContract: destToken.address, amount: amount, focusSrc: true) { [weak self] rates in
        self?.platformRates.value = rates
      }
    }
  }
  
  func reloadSourceBalance() {
    guard let sourceToken = sourceToken.value else {
      sourceBalance.value = nil
      return
    }
    swapRepository.getBalance(tokenAddress: sourceToken.address, address: addressString) { [weak self] (amount, tokenAddress) in
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
    swapRepository.getBalance(tokenAddress: destToken.address, address: addressString) { [weak self] (amount, tokenAddress) in
      if tokenAddress == destToken.address { // Needed to handle case swap pair
        self?.destBalance.value = amount
      }
    }
  }
  
  func selectPlatform(platform: String) {
    self.selectedPlatformName = platform
    self.sortedRates = self.sortedRates(rates: platformRates.value)
  }
  
  func updateSourceToken(token: Token) {
    self.sourceBalance.value = nil
    self.sourceToken.value = token
    self.sourceAmountValue = nil
    self.selectedPlatformName = nil
    self.reloadSourceBalance()
  }
  
  func updateDestToken(token: Token) {
    self.destBalance.value = nil
    self.destToken.value = token
    self.sourceAmount.value = self.sourceAmount.value // Trigger reload
    self.selectedPlatformName = nil
    self.reloadSourceBalance()
    self.reloadDestBalance()
  }
  
  func swapPair() {
    (sourceBalance.value, destBalance.value) = (destBalance.value, sourceBalance.value)
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
    let decimals = KNGeneralProvider.shared.quoteTokenObject.decimals
    let rateUSDDouble = KNGeneralProvider.shared.quoteTokenPrice?.usd ?? 0
    let rateBigInt = BigInt(rateUSDDouble * pow(10.0, Double(decimals)))
    let feeUSD = (estGas * gasPrice * rateBigInt) / BigInt(10).power(decimals)
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
  
  private func createPlatformRatesViewModels(destToken: Token, sortedRates: [Rate]) -> [SwapPlatformItemViewModel] {
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
                                       quoteToken: currentChain.value.quoteTokenObject(),
                                       destToken: destToken,
                                       gasFeeUsd: self.getGasFeeUSD(estGas: BigInt(rate.estimatedGas), gasPrice: self.gasPrice),
                                       showSaveTag: sortedRates.count > 1 && index == 0 && savedAmount > BigInt(0.1 * pow(10.0, 18.0)),
                                       savedAmount: savedAmount)
    }
  }
  
  private func getPriceImpactState(change: Double) -> PriceImpactState {
    let absChange = abs(change)
    if 0 <= absChange && absChange < 5 {
      return .normal
    }
    if 5 <= absChange && absChange < 15 {
      return .high
    }
    return .veryHigh
  }
  
  private func getRateString() -> String? {
    guard let destToken = destToken.value, let sourceToken = sourceToken.value else {
      return nil
    }
    guard let selectedPlatform = selectedPlatformRate.value else {
      return nil
    }
    if showRevertedRate {
      let rate = BigInt(selectedPlatform.rate) ?? .zero
      let revertedRate = rate.isZero ? 0 : (BigInt(10).power(36) / rate)
      let rateString = NumberFormatUtils.rate(value: revertedRate, decimals: 18)
      return "1 \(destToken.symbol) = \(rateString) \(sourceToken.symbol)"
    } else {
      let rateString = NumberFormatUtils.rate(value: BigInt(selectedPlatform.rate) ?? .zero, decimals: 18)
      return "1 \(sourceToken.symbol) = \(rateString) \(destToken.symbol)"
    }
  }
  
  private func observeNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidSwitchChain),
      name: AppEventCenter.shared.kAppDidSwitchChain,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidSwitchAddress),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  @objc func appDidSwitchChain() {
    if KNGeneralProvider.shared.currentChain != currentChain.value {
      currentChain.value = KNGeneralProvider.shared.currentChain
      sourceToken.value = KNGeneralProvider.shared.quoteTokenObject.toData()
      sourceBalance.value = nil
      destBalance.value = nil
      destToken.value = nil
      sourceAmountValue = nil
      loadBaseToken()
      reloadSourceBalance()
    }
  }
  
  @objc func appDidSwitchAddress() {
    currentAddress.value = AppDelegate.session.address
    sourceBalance.value = nil
    destBalance.value = nil
    reloadSourceBalance()
    reloadDestBalance()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidChangeAddress, object: nil)
  }
  
}

extension SwapV2ViewModel {
  
  func didTapChainButton() {
    actions.onSelectSwitchChain()
  }
  
  func didTapWalletButton() {
    actions.onSelectSwitchWallet()
  }
  
  func didTapHistoryButton() {
    actions.onSelectOpenHistory()
  }
  
  func didTapContinue() {
    switch state.value {
    case .notApproved:
      approve()
    case .ready:
      guard let sourceToken = sourceToken.value, let destToken = destToken.value else { return }
      guard let selectedRate = selectedPlatformRate.value else { return }
      guard let sourceAmount = sourceAmount.value else { return }
      let swapObject = SwapObject(sourceToken: sourceToken,
                                  destToken: destToken,
                                  sourceAmount: sourceAmount,
                                  rate: selectedRate)
      actions.openSwapConfirm(swapObject)
    default:
      return
    }
  }
  
}
