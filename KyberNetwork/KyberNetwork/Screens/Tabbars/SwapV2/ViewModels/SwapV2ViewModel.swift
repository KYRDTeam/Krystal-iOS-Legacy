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
  var openSettings: (_ gasLimit: BigInt, _ settings: SwapTransactionSettings) -> ()
}

class SwapV2ViewModel: SwapInfoViewModelProtocol {

  var actions: SwapV2ViewModelActions
  
  private(set) var selectedPlatformName: String? {
    didSet {
      self.selectedPlatformRate.value = platformRates.value.first(where: { rate in
        rate.platform == selectedPlatformName
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
  
  var settings: SwapTransactionSettings = .default
  
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
  
  var state: Observable<SwapState> = .init(.emptyAmount)
  
  private let swapRepository = SwapRepository()

  init(actions: SwapV2ViewModelActions) {
    slippageString.value = "\(String(format: "%.1f", self.settings.slippage))%"
    
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
        self.selectedPlatformName = nil
        self.state.value = .emptyAmount
      } else {
        self.reloadRates(amount: amount!)
      }
    }
    platformRates.observe(on: self) { [weak self] rates in
      guard let self = self else { return }
      self.selectedPlatformName = rates.first?.platform
      self.sortedRates = self.sortedRates(rates: rates)
      if rates.isEmpty {
        self.state.value = .rateNotFound
      } else {
        if self.currentAddress.value.isWatchWallet {
          self.state.value = .notConnected
        } else if self.sourceAmount.value ?? .zero <= self.maxAvailableSourceTokenAmount {
          self.state.value = .checkingAllowance
          self.checkAllowance()
        } else {
          self.state.value = .insufficientBalance
        }
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
    swapRepository.getAllowance(tokenAddress: sourceToken.value?.address ?? "", address: addressString) { [weak self] allowance, _ in
      guard let self = self else { return }
      if allowance < self.sourceAmount.value ?? .zero {
        if self.isApproving() {
          self.state.value = .approving
        } else {
          self.state.value = .notApproved(currentAllowance: allowance)
        }
      } else {
        self.state.value = .ready
      }
    }
  }
  
  func reloadRates(amount: BigInt) {
    self.selectedPlatformName = nil
    self.priceImpactState.value = .normal
    guard let sourceToken = sourceToken.value, let destToken = destToken.value else {
      return
    }
    self.state.value = .fetchingRates
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
  
  func selectPlatform(platform: String) {
    self.selectedPlatformName = platform
    self.sortedRates = self.sortedRates(rates: platformRates.value)
  }
  
  func updateSourceToken(token: Token) {
    if token.address == destToken.value?.address {
      error.value = .sameSourceDestToken
      return
    }
    self.sourceBalance.value = nil
    self.sourceToken.value = token
    self.sourceAmount.value = nil
    self.selectedPlatformName = nil
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
    self.selectedPlatformName = nil
    self.reloadSourceBalance()
    self.loadDestTokenPrice()
    self.reloadDestBalance()
  }
  
  func swapPair() {
    (sourceBalance.value, destBalance.value) = (destBalance.value, sourceBalance.value)
    (sourceToken.value, destToken.value) = (destToken.value, sourceToken.value)
    self.sourceAmount.value = nil
    self.selectedPlatformName = nil
    self.loadSourceTokenPrice()
    self.loadDestTokenPrice()
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
    reloadRates(amount: amount)
  }
  
  func updateSettings(settings: SwapTransactionSettings) {
    self.settings = settings
    updateInfo()
  }
  
  func isApproving() -> Bool {
    let allTransactions = EtherscanTransactionStorage.shared.getInternalHistoryTransaction()
    let pendingApproveTxs = allTransactions.filter { tx in
      return tx.transactionDetailDescription.lowercased() == sourceToken.value?.address.lowercased() && tx.type == .allowance
    }
    return !pendingApproveTxs.isEmpty
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
  
  private func createPlatformRatesViewModels(destToken: Token, sortedRates: [Rate]) -> [SwapPlatformItemViewModel] {
    let destTokenPrice = destTokenPrice.value ?? 0
    var savedAmount: BigInt = 0
    if sortedRates.count >= 2 {
      let diffAmount = (BigInt(sortedRates[0].amount) ?? BigInt(0)) - (BigInt(sortedRates[1].amount) ?? BigInt(0))
      let diffFee = BigInt(sortedRates[0].estimatedGas) - BigInt(sortedRates[1].estimatedGas)
      let diffAmountUSD = diffAmount * BigInt(destTokenPrice * pow(10.0, 18.0)) / BigInt(10).power(destToken.decimals)
      let diffFeeUSD = diffFee * self.getGasFeeUSD(estGas: diffFee, gasPrice: self.gasPrice)
      savedAmount = diffAmountUSD - diffFeeUSD
    }
    return sortedRates.enumerated().map { index, rate in
      return SwapPlatformItemViewModel(platformRate: rate,
                                       isSelected: rate.platform == selectedPlatformName,
                                       quoteToken: currentChain.value.quoteTokenObject(),
                                       destToken: destToken,
                                       destTokenPrice: destTokenPrice,
                                       gasFeeUsd: self.getGasFeeUSD(estGas: BigInt(rate.estGasConsumed ?? 0), gasPrice: self.gasPrice),
                                       showSaveTag: index == 0,
                                       savedAmount: savedAmount)
    }
  }
  
  private func getSourceAmountUsdString(amount: BigInt?) -> String? {
    guard let sourceToken = sourceToken.value, let sourceTokenPrice = sourceTokenPrice.value, let amount = amount else {
      return nil
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
      currentChain.value = KNGeneralProvider.shared.currentChain
      sourceToken.value = KNGeneralProvider.shared.quoteTokenObject.toData()
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
    actions.openSettings(gasLimit, settings)
  }
  
}

// MARK: Update from settings
extension SwapV2ViewModel {
  
  func updateInfo() {
    guard let destToken = destToken.value else { return }
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
  
  func updateSlippage(slippage: Double) {
    settings.slippage = slippage
    slippageString.value = "\(String(format: "%.1f", self.settings.slippage))%"
    updateInfo()
  }
  
  func updateGasPriceType(type: KNSelectedGasPriceType) {
    settings.basic = .init(gasPriceType: type)
    settings.advanced = nil
    updateInfo()
  }
  
  func updateAdvancedNonce(nonce: Int) {
    if let advanced = settings.advanced {
      settings.basic = nil
      settings.advanced = .init(gasLimit: advanced.gasLimit,
                                maxFee: advanced.maxFee,
                                maxPriorityFee: advanced.maxPriorityFee,
                                nonce: nonce)
    } else if let basic = settings.basic {
      settings.basic = nil
      settings.advanced = .init(gasLimit: gasLimit,
                                maxFee: gasPrice,
                                maxPriorityFee: getPriorityFee(forType: basic.gasPriceType) ?? .zero,
                                nonce: nonce)
    }
    updateInfo()
  }
  
  func updateAdvancedFee(maxFee: BigInt, maxPriorityFee: BigInt, gasLimit: BigInt) {
    if let advanced = settings.advanced {
      settings.basic = nil
      settings.advanced = .init(gasLimit: gasLimit,
                                maxFee: maxFee,
                                maxPriorityFee: maxPriorityFee,
                                nonce: advanced.nonce)
    } else {
      settings.basic = nil
      settings.advanced = .init(gasLimit: gasLimit,
                                maxFee: maxFee,
                                maxPriorityFee: maxPriorityFee,
                                nonce: NonceCache.shared.getCachingNonce(address: addressString, chain: currentChain.value))
    }
    updateInfo()
  }
  
}
