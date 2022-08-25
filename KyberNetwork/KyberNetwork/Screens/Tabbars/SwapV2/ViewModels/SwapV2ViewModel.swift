//
//  SwapV2ViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import Foundation
import BigInt
import KrystalWallets
import Result

struct SwapV2ViewModelActions {
  var onSelectSwitchChain: () -> ()
  var onSelectSwitchWallet: () -> ()
  var onSelectOpenHistory: () -> ()
  var openSwapConfirm: (SwapObject) -> ()
  var openApprove: (_ token: TokenObject, _ amount: BigInt) -> ()
  var openSettings: (_ gasLimit: BigInt,_ rate: Rate?,_ settings: SwapTransactionSettings) -> ()
}

class SwapV2ViewModel: SwapInfoViewModelProtocol {

  var actions: SwapV2ViewModelActions
  
  private(set) var selectedPlatformHint: String? {
    didSet {
      self.selectedPlatformRate.value = self.platformRates.value.first(where: { rate in
        rate.hint == selectedPlatformHint
      })
      guard let destToken = destToken.value, let sourceToken = sourceToken.value else {
        return
      }
      self.rateString.value = self.getRateString(sourceToken: sourceToken, destToken: destToken)
      self.minReceiveString.value = self.selectedPlatformRate.value.map {
        return self.getMinReceiveString(destToken: destToken, rate: $0)
      }
      self.estimatedGasFeeString.value = self.selectedPlatformRate.value.map {
        return self.getEstimatedNetworkFeeString(rate: $0)
      }
      self.maxGasFeeString.value = self.selectedPlatformRate.value.map {
        return self.getMaxNetworkFeeString(rate: $0)
      }
      self.priceImpactString.value = self.selectedPlatformRate.value.map {
        return self.getPriceImpactString(rate: $0)
      }
      self.priceImpactState.value = self.selectedPlatformRate.value.map {
        return self.getPriceImpactState(change: Double($0.priceImpact) / 100)
      } ?? .normal
      
      if self.priceImpactState.value == .veryHighNeedExpertMode || self.priceImpactState.value == .outOfNegativeRange {
        self.state.value = .requiredExpertMode
      } else {
        self.state.value = .ready
      }
    }
  }
  
  var showRevertedRate: Bool = false {
    didSet {
      guard let sourceToken = sourceToken.value, let destToken = destToken.value else {
        return
      }
      self.rateString.value = self.getRateString(sourceToken: sourceToken, destToken: destToken)
    }
  }
  
  var isInputValid: Bool {
    return sourceToken.value != nil && destToken.value != nil && !(sourceAmount.value ?? .zero).isZero
  }

  var addressString: String {
    return currentAddress.value.addressString
  }
  
  var numberOfRateRows: Int {
    return platformRatesViewModels.value.count
  }
  
  var isEIP1559: Bool {
    return currentChain.value.isSupportedEIP1559()
  }
  
  var isSourceTokenQuote: Bool {
    return sourceToken.value?.address.lowercased() == currentChain.value.quoteTokenObject().address.lowercased()
  }
  
  var maxAvailableSourceTokenAmount: BigInt {
    guard let balance = sourceBalance.value, !balance.isZero else {
      return .zero
    }
    if isSourceTokenQuote {
      if balance <= gasPrice * gasLimit {
        return .zero
      }
      return balance - gasPrice * gasLimit
    } else {
      return sourceBalance.value ?? .zero
    }
  }
  
  var selectedRate: Rate? {
    return selectedPlatformRate.value
  }
  
  var settings: SwapTransactionSettings {
    return settingsObservable.value
  }
  
  let fetchingBalanceInterval: Double = 10.0
  var timer: Timer?
  
  var currentAddress: Observable<KAddress> = .init(AppDelegate.session.address)
  var currentChain: Observable<ChainType> = .init(KNGeneralProvider.shared.currentChain)
  var sourceToken: Observable<Token?> = .init(KNGeneralProvider.shared.quoteTokenObject.toData())
  var destToken: Observable<Token?> = .init(nil)
  var platformRatesViewModels: Observable<[SwapPlatformItemViewModel]> = .init([])
  var sourceBalance: Observable<BigInt?> = .init(nil)
  var destBalance: Observable<BigInt?> = .init(nil)
  var sourceTokenPrice: Observable<Double?> = .init(nil)
  var destTokenPrice: Observable<Double?> = .init(nil)
  var selectedPlatformRate: Observable<Rate?> = .init(nil)
  var sourceAmount: Observable<BigInt?> = .init(nil)
  var platformRates: Observable<[Rate]> = .init([])
  var souceAmountUsdString: Observable<String?> = .init(nil)
  
  var rateString: Observable<String?> = .init(nil)
  var slippageString: Observable<String?> = .init(nil)
  var minReceiveString: Observable<String?> = .init(nil)
  var estimatedGasFeeString: Observable<String?> = .init(nil)
  var maxGasFeeString: Observable<String?> = .init(nil)
  var priceImpactString: Observable<String?> = .init(nil)
  var routeString: Observable<String?> = .init(nil)
  var priceImpactState: Observable<PriceImpactState> = .init(.normal)
  var hasPendingTransaction: Observable<Bool> = .init(false)
  var error: Observable<SwapError?> = .init(nil)
  
  var isExpanding: Observable<Bool> = .init(false)
  var state: Observable<SwapState> = .init(.emptyAmount)
  var settingsObservable: Observable<SwapTransactionSettings> = .init(SwapTransactionSettings.getDefaultSettings())
  
  private let swapRepository = SwapRepository()

  init(actions: SwapV2ViewModelActions) {
    slippageString.value = NumberFormatUtils.percent(value: self.settingsObservable.value.slippage)
    
    self.actions = actions
    self.scheduleFetchingBalance()
    self.observeNotifications()
    self.selfObserve()
    self.loadSourceTokenPrice()
    self.loadBaseToken()
    self.reloadSourceBalance()
  }
  
  func loadSourceTokenPrice() {
    guard let sourceToken = sourceToken.value else { return }
    swapRepository.getTokenDetail(tokenAddress: sourceToken.address) { [weak self] token in
      if token?.address == sourceToken.address { // Needed to handle case swap pair
        self?.sourceTokenPrice.value = token?.markets["usd"]?.price
      }
    }
  }
  
  func loadDestTokenPrice() {
    guard let destToken = destToken.value else { return }
    swapRepository.getTokenDetail(tokenAddress: destToken.address) { [weak self] token in
      if token?.address == destToken.address { // Needed to handle case swap pair
        self?.destTokenPrice.value = token?.markets["usd"]?.price
      }
    }
  }
  
  func loadBaseToken() {
    swapRepository.getCommonBaseTokens { [weak self] tokens in
      self?.destToken.value = tokens.first
      self?.loadDestTokenPrice()
      self?.reloadDestBalance()
    }
  }
  
  func selfObserve() {
    sourceAmount.observeAndFire(on: self) { [weak self] amount in
      guard let self = self else { return }
      self.souceAmountUsdString.value = self.getSourceAmountUsdString(amount: amount)
      if amount == nil || amount!.isZero {
        self.selectedPlatformHint = nil
        self.state.value = .emptyAmount
      } else {
        self.reloadRates(amount: amount!, isRefresh: false)
      }
    }
    sourceTokenPrice.observeAndFire(on: self) { [weak self] _ in
      guard let self = self else { return }
      self.souceAmountUsdString.value = self.getSourceAmountUsdString(amount: self.sourceAmount.value)
    }
    platformRates.observe(on: self) { [weak self] rates in
      guard let self = self else { return }
      guard self.state.value.isActiveState else {
        return
      }
      let sortedRates = self.getSortedRates(rates: rates, sortBySelected: !self.isExpanding.value)
      if !rates.contains(where: { $0.hint == self.selectedPlatformHint }) {
        let oldPlatformName = self.selectedPlatformRate.value?.platformShort
        self.selectedPlatformHint = sortedRates.first?.hint
        let newPlatformName = sortedRates.first?.platformShort
        if let oldName = oldPlatformName, let newName = newPlatformName {
          self.error.value = .rateHasBeenChanged(oldRate: oldName, newRate: newName)
        }
      }
      self.platformRatesViewModels.value = self.createPlatformRatesViewModels(sortedRates: sortedRates)
      if sortedRates.isEmpty {
        self.state.value = .rateNotFound
      } else {
        if self.currentAddress.value.isWatchWallet {
          self.state.value = .notConnected
        } else if self.sourceAmount.value ?? .zero <= self.maxAvailableSourceTokenAmount {
          self.checkAllowance()
        } else {
          self.state.value = .insufficientBalance
        }
      }
    }
    sourceToken.observe(on: self) { [weak self] token in
      if token?.address.lowercased() == self?.destToken.value?.address.lowercased() {
        self?.error.value = .sameSourceDestToken
      }
    }
    destToken.observe(on: self) { [weak self] token in
      if token?.address.lowercased() == self?.sourceToken.value?.address.lowercased() {
        self?.error.value = .sameSourceDestToken
      }
    }
  }
  
  func approve(_ amount: BigInt) {
    guard let sourceTokenObject = sourceToken.value?.toObject() else {
      return
    }
    actions.openApprove(sourceTokenObject, amount)
  }
  
  func checkAllowance() {
    self.state.value = .checkingAllowance
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.swapRepository.getAllowance(tokenAddress: self.sourceToken.value?.address ?? "", address: self.addressString) { [weak self] allowance, _ in
        guard let self = self else { return }
        if allowance < self.sourceAmount.value ?? .zero {
          if self.isApproving() {
            self.state.value = .approving
          } else {
            self.state.value = .notApproved(currentAllowance: allowance)
          }
        } else if self.priceImpactState.value == .veryHighNeedExpertMode || self.priceImpactState.value == .outOfNegativeRange {
          self.state.value = .requiredExpertMode
        } else {
          self.state.value = .ready
        }
      }
    }
  }
  
  func reloadRates(amount: BigInt, isRefresh: Bool) {
    guard let sourceToken = sourceToken.value, let destToken = destToken.value else {
      return
    }
    if !isRefresh {
      self.selectedPlatformHint = nil
      self.priceImpactState.value = .normal
    }
    self.state.value = isRefresh ? .refreshingRates : .fetchingRates
    self.swapRepository.getAllRates(address: addressString, srcTokenContract: sourceToken.address, destTokenContract: destToken.address, amount: amount, focusSrc: true) { [weak self] rates in
      self?.platformRates.value = rates
    }
  }
  
  func reloadSourceBalance() {
    guard let sourceToken = sourceToken.value else {
      sourceBalance.value = nil
      return
    }
    swapRepository.getBalance(tokenAddress: sourceToken.address, address: addressString) { [weak self] (amount, tokenAddress) in
      if tokenAddress == self?.sourceToken.value?.address, let amount = amount { // Needed to handle case swap pair
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
      if tokenAddress == destToken.address, let amount = amount { // Needed to handle case swap pair
        self?.destBalance.value = amount
      }
    }
  }
  
  func approve(tokenAddress: String, currentAllowance: BigInt, gasLimit: BigInt) {
    state.value = .approving
    swapRepository.approve(address: currentAddress.value, tokenAddress: tokenAddress, currentAllowance: currentAllowance, gasPrice: gasPrice, gasLimit: gasLimit) { [weak self] result in
      switch result {
      case .success:
        return
      case .failure(let error):
        self?.error.value = .approvalFailed(error: error)
        self?.state.value = .notApproved(currentAllowance: currentAllowance)
      }
    }
  }
  
  func selectPlatform(hint: String) {
    self.selectedPlatformHint = hint
    self.reloadPlatformRatesViewModels()
  }
  
  func reloadPlatformRatesViewModels() {
    let rates = self.getSortedRates(rates: self.platformRates.value, sortBySelected: !isExpanding.value)
    self.platformRatesViewModels.value = self.createPlatformRatesViewModels(sortedRates: rates)
  }
  
  func updateSourceToken(token: Token) {
    if token.address == destToken.value?.address {
      error.value = .sameSourceDestToken
      return
    }
    self.sourceBalance.value = nil
    self.sourceToken.value = token
    self.sourceAmount.value = nil
    self.selectedPlatformHint = nil
    self.loadSourceTokenPrice()
    self.reloadSourceBalance()
  }
  
  func updateDestToken(token: Token) {
    if token.address == sourceToken.value?.address {
      error.value = .sameSourceDestToken
      return
    }
    self.destBalance.value = nil
    self.destToken.value = token
    self.sourceAmount.value = self.sourceAmount.value // Trigger reload
    self.selectedPlatformHint = nil
    self.reloadSourceBalance()
    self.loadDestTokenPrice()
    self.reloadDestBalance()
  }
  
  func swapPair() {
    (sourceBalance.value, destBalance.value) = (destBalance.value, sourceBalance.value)
    (sourceToken.value, destToken.value) = (destToken.value, sourceToken.value)
    self.sourceAmount.value = nil
    self.selectedPlatformHint = nil
    self.loadSourceTokenPrice()
    self.loadDestTokenPrice()
    self.reloadSourceBalance()
    self.reloadDestBalance()
  }
  
  func reloadRates(isRefresh: Bool) {
    guard let amount = self.sourceAmount.value, !amount.isZero else {
      return
    }
    reloadRates(amount: amount, isRefresh: isRefresh)
  }
  
  func isApproving() -> Bool {
    let allTransactions = EtherscanTransactionStorage.shared.getInternalHistoryTransaction()
    let pendingApproveTxs = allTransactions.filter { tx in
      return tx.transactionDetailDescription.lowercased() == sourceToken.value?.address.lowercased() && tx.type == .allowance
    }
    return !pendingApproveTxs.isEmpty
  }
  
  private func getSortedRates(rates: [Rate], sortBySelected: Bool) -> [Rate] {
    guard let destToken = destToken.value else { return [] }
    let price = destTokenPrice.value ?? 0
    
    if rates.isEmpty { return [] }
    
    let sortedRates = rates.sorted { lhs, rhs in
      return diffInUSD(lhs: lhs, rhs: rhs, destToken: destToken, destTokenPrice: price) > 0
    }
    return [sortedRates.first!] + sortedRates.dropFirst().sorted { lhs, rhs in
      if lhs.hint == selectedPlatformHint && sortBySelected {
        return true
      }
      return diffInUSD(lhs: lhs, rhs: rhs, destToken: destToken, destTokenPrice: price) > 0
    }
  }
  
  private func createPlatformRatesViewModels(sortedRates: [Rate]) -> [SwapPlatformItemViewModel] {
    guard let destToken = destToken.value else { return [] }
    var savedAmount: BigInt = 0
    if sortedRates.count >= 2 {
      savedAmount = diffInUSD(lhs: sortedRates[0], rhs: sortedRates[1], destToken: destToken, destTokenPrice: destTokenPrice.value ?? 0)
    }
    return sortedRates.enumerated().map { index, rate in
      return SwapPlatformItemViewModel(platformRate: rate,
                                       isSelected: rate.hint == selectedPlatformHint,
                                       quoteToken: currentChain.value.quoteTokenObject(),
                                       destToken: destToken,
                                       destTokenPrice: destTokenPrice.value,
                                       gasFeeUsd: self.getGasFeeUSD(estGas: BigInt(rate.estGasConsumed ?? 0), gasPrice: self.gasPrice),
                                       showSaveTag: index == 0,
                                       savedAmount: savedAmount)
    }
  }
  
  private func getSourceAmountUsdString(amount: BigInt?) -> String? {
    guard let sourceToken = sourceToken.value, let amount = amount else {
      return nil
    }
    guard let sourceTokenPrice = sourceTokenPrice.value else {
      return "-"
    }
    let amountUSD = amount * BigInt(sourceTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(sourceToken.decimals)
    let formattedAmountUSD = NumberFormatUtils.usdAmount(value: amountUSD, decimals: 18)
    return "~$\(formattedAmountUSD)"
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidChangeAddress, object: nil)
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidSwitchChain, object: nil)
    timer?.invalidate()
    timer = nil
  }
  
}

extension SwapV2ViewModel {
  
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
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.transactionStateDidUpdate),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
  }
  
  @objc func appDidSwitchChain() {
    if KNGeneralProvider.shared.currentChain != currentChain.value {
      checkPendingTx()
      settingsObservable.value = SwapTransactionSettings.getDefaultSettings()
      currentChain.value = KNGeneralProvider.shared.currentChain
      sourceToken.value = KNGeneralProvider.shared.quoteTokenObject.toData()
      sourceTokenPrice.value = nil
      destTokenPrice.value = nil
      state.value = .emptyAmount
      sourceBalance.value = nil
      destBalance.value = nil
      destToken.value = nil
      sourceAmount.value = nil
      timer?.invalidate()
      timer = nil
      scheduleFetchingBalance()
      loadBaseToken()
      reloadSourceBalance()
    }
  }
  
  @objc func appDidSwitchAddress() {
    checkPendingTx()
    currentAddress.value = AppDelegate.session.address
    state.value = .emptyAmount
    sourceAmount.value = nil
    sourceBalance.value = nil
    destBalance.value = nil
    loadSourceTokenPrice()
    loadDestTokenPrice()
    reloadSourceBalance()
    reloadDestBalance()
  }
  
  @objc func transactionStateDidUpdate() {
    checkPendingTx()
  }
  
  func checkPendingTx() {
    let pendingTransaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().first { transaction in
      transaction.state == .pending
    }
    hasPendingTransaction.value = pendingTransaction != nil
  }
  
  func scheduleFetchingBalance() {
    timer = Timer.scheduledTimer(withTimeInterval: fetchingBalanceInterval, repeats: true, block: { [weak self] _ in
      self?.loadSourceTokenPrice()
      self?.loadDestTokenPrice()
      self?.reloadSourceBalance()
      self?.reloadDestBalance()
    })
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
    case .notApproved(let currentAllowance):
      approve(currentAllowance)
    case .ready:
      guard let sourceToken = sourceToken.value, let destToken = destToken.value else { return }
      guard let selectedRate = selectedPlatformRate.value else { return }
      guard let sourceAmount = sourceAmount.value else { return }
        
      let swapObject = SwapObject(sourceToken: sourceToken,
                                  destToken: destToken,
                                  sourceAmount: sourceAmount,
                                  rate: selectedRate,
                                  showRevertedRate: self.showRevertedRate,
                                  priceImpactState: self.priceImpactState.value,
                                  sourceTokenPrice: self.sourceTokenPrice.value ?? 0,
                                  destTokenPrice: self.destTokenPrice.value ?? 0,
                                  swapSetting: self.settings)
      actions.openSwapConfirm(swapObject)
    default:
      return
    }
  }
  
  func openSettings() {
    let selectedRate = selectedPlatformRate.value
    actions.openSettings(gasLimit, selectedRate, settings)
  }
  
}

// MARK: Update from settings
extension SwapV2ViewModel {
  
  func updateInfo() {
    guard let destToken = destToken.value else { return }
    self.slippageString.value = NumberFormatUtils.percent(value: self.settings.slippage)
    self.minReceiveString.value = self.selectedPlatformRate.value.map {
      return self.getMinReceiveString(destToken: destToken, rate: $0)
    }
    self.estimatedGasFeeString.value = self.selectedPlatformRate.value.map {
      return self.getEstimatedNetworkFeeString(rate: $0)
    }
    self.maxGasFeeString.value = self.selectedPlatformRate.value.map {
      return self.getMaxNetworkFeeString(rate: $0)
    }
  }
  
  func updateSettings(settings: SwapTransactionSettings) {
    self.settingsObservable.value = settings
    
    if priceImpactState.value == .veryHighNeedExpertMode || priceImpactState.value == .outOfNegativeRange, settings.expertModeOn {
      priceImpactState.value = .veryHigh
      state.value = .ready
    } else if priceImpactState.value == .veryHigh, !settings.expertModeOn {
      guard let selectedRate = self.selectedPlatformRate.value else { return }
      priceImpactState.value = self.getPriceImpactState(change: Double(selectedRate.priceImpact) / 100)
      state.value = .requiredExpertMode
    } else if !state.value.isActiveState {
      self.updateInfo()
      return
    }
    
    self.updateInfo()
    self.reloadPlatformRatesViewModels()
  }
  
}
