//
//  EarnSwapViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/5/21.
//

import UIKit
import BigInt
import KrystalWallets

//swiftlint:disable file_length
class EarnSwapViewModel {
  fileprivate var fromTokenData: TokenData?
  fileprivate var toTokenData: TokenData
  fileprivate var platformDataSource: [EarnSelectTableViewCellViewModel]
  var isSwapAllBalance: Bool = false
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var baseGasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
//  fileprivate(set) var wallet: Wallet
  var showingRevertRate: Bool = false
  var advancedGasLimit: String? {
    didSet {
      if self.advancedGasLimit != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedMaxPriorityFee: String? {
    didSet {
      if self.advancedMaxPriorityFee != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedMaxFee: String? {
    didSet {
      if self.advancedMaxFee != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedNonce: String? {
    didSet {
      if self.advancedNonce != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }
  
  var swapRates: (String, String, BigInt, [Rate]) = ("", "", BigInt(0), [])
  var currentFlatform: String = "Kyber" {
    didSet {
      let dict = self.swapRates.3.first { (element) -> Bool in
        return element.platform == self.currentFlatform
      }
      self.gasLimit = BigInt(dict?.estimatedGas ?? 0)
    }
  }
  var remainApprovedAmount: (TokenData, BigInt)?
  var latestNonce: Int = -1
  var refPrice: (from: TokenData, to: TokenData, priceString: String, sources: [String])?
  fileprivate(set) var minRatePercent: Double = 0.5
  var gasPriceSelectedAmount: (String, String) = ("", "")
  var approvingToken: TokenObject?

  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  init(to: TokenData, from: TokenData?) {
    self.fromTokenData = from
    self.toTokenData = to
    let dataSource = self.toTokenData.lendingPlatforms.map { EarnSelectTableViewCellViewModel(platform: $0) }
    let optimizeValue = dataSource.max { (left, right) -> Bool in
      return left.supplyRate < right.supplyRate
    }
    if let notNilValue = optimizeValue {
      notNilValue.isSelected = true
    }
    self.platformDataSource = dataSource
//    self.wallet = wallet
  }
  
  func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }
  
  func updateBalance(_ balances: [String: Balance]) {
  }
  
  func updateFromToken(_ token: TokenData) {
    self.fromTokenData = token
  }
  
  func resetBalances() {
  }

  var displayExpectedReceiveValue: String? {
    return self.isFocusingFromAmount ? self.displayMinDestAmount : self.displayMaxSoldAmount
  }

  var displayExpectedReceiveTitle: String {
    return self.isFocusingFromAmount ? "Minimum received" : "Maximum sold"
  }

  var displayBalance: String? {
    guard let fromTokenData = fromTokenData else {
      return nil
    }
    let string = fromTokenData.getBalanceBigInt().string(
      decimals: fromTokenData.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(fromTokenData.decimals, 5)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }

  var totalBalanceText: String? {
    guard let fromTokenData = fromTokenData, let displayBalance = displayBalance else {
      return nil
    }
    return "\(displayBalance) \(fromTokenData.symbol)"
  }

  func updateAmount(_ amount: String, isSource: Bool, forSendAllETH: Bool = false) {
    if isSource {
      self.amountFrom = amount
      guard !forSendAllETH else {
        return
      }
      self.isSwapAllBalance = false
    } else {
      self.amountTo = amount
    }
  }
  
  var amountToBigInt: BigInt {
    return amountTo.amountBigInt(decimals: self.toTokenData.decimals) ?? BigInt(0)
  }

  var isAmountTooSmall: Bool {
    guard let fromTokenData = fromTokenData else {
      return false
    }
    if fromTokenData.symbol == "ETH" { return false }
    return self.amountFromBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    guard let fromTokenData = fromTokenData else {
      return false
    }
    let balanceVal = fromTokenData.getBalanceBigInt()
    return self.amountFromBigInt > balanceVal
  }
  
  var amountFromBigInt: BigInt {
    guard let decimals = fromTokenData?.decimals else { return BigInt(0) }
    return self.amountFrom.removeGroupSeparator().amountBigInt(decimals: decimals) ?? BigInt(0)
  }
  
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }
  
  var allTokenBalanceString: String? {
    guard let fromTokenData = fromTokenData else {
      return nil
    }
    if fromTokenData.isQuoteToken {
      let balance = fromTokenData.getBalanceBigInt()
      let availableValue = max(BigInt(0), balance - self.allETHBalanceFee)
      let string = availableValue.string(
        decimals: fromTokenData.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(fromTokenData.decimals, 5)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.displayBalance?.removeGroupSeparator()
  }
  
  var priceImpactValue: Double {
    guard let fromTokenData = fromTokenData else {
      return 0
    }
    guard !self.amountFrom.isEmpty else {
      return 0
    }
    let refPrice = self.getRefPrice(from: fromTokenData, to: self.toTokenData)
    let price = self.getSwapRate(from: fromTokenData.address.lowercased(), to: self.toTokenData.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)

    guard !price.isEmpty, !refPrice.isEmpty, let priceBigInt = BigInt(price) else {
      return 0
    }
    let refPriceDouble = refPrice.doubleValue
    let priceDouble: Double = Double(priceBigInt) / pow(10.0, 18)
    let change = (priceDouble - refPriceDouble) / refPriceDouble * 100.0
    return change
  }
  
  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) { //TODO: can be improve with enum function
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    case .custom:
      if let customGasPrice = self.advancedMaxFee?.shortBigInt(units: UnitConfiguration.gasPriceUnit),
          let customGasLimitString = self.advancedGasLimit,
          let customGasLimit = BigInt(customGasLimitString) {
        self.gasPrice = customGasPrice
        self.gasLimit = customGasLimit
      }
    default: return
    }
  }

  func resetAdvancedSettings() {
    self.advancedGasLimit = nil
    self.advancedMaxPriorityFee = nil
    self.advancedMaxFee = nil
    self.advancedNonce = nil
    if self.selectedGasPriceType == .custom {
      self.selectedGasPriceType = .medium
    }
    self.gasLimit = self.baseGasLimit
  }
  
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee = gasPrice * self.gasLimit
    let feeString: String = fee.displayRate(decimals: 18)
    var typeString = ""
    switch self.selectedGasPriceType {
    case .superFast:
      typeString = "super.fast".toBeLocalised().uppercased()
    case .fast:
      typeString = "fast".toBeLocalised().uppercased()
    case .medium:
      typeString = "regular".toBeLocalised().uppercased()
    case .slow:
      typeString = "slow".toBeLocalised().uppercased()
    case .custom:
      typeString = "custom".toBeLocalised().uppercased()
    }
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken) (\(typeString))"
  }
  //TODO: can be improve with extension
  var gasFeeString: String {
    self.updateSelectedGasPriceType(self.selectedGasPriceType)
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }
  
  var selectedPlatform: String {
    let selected = self.platformDataSource.first { $0.isSelected == true }
    return selected?.platform ?? ""
  }

  var minDestQty: BigInt {
    return self.amountToBigInt * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var maxAmtSold: BigInt {
    return self.amountFromBigInt * BigInt(10000.0 + self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var displayMinDestAmount: String {
    return self.minDestQty.string(decimals: self.toTokenData.decimals, minFractionDigits: 4, maxFractionDigits: 4) + " " + self.toTokenData.symbol
  }
  
  var displayMaxSoldAmount: String? {
    guard let fromTokenData = fromTokenData else {
      return nil
    }
    return self.maxAmtSold.string(decimals: fromTokenData.decimals, minFractionDigits: 4, maxFractionDigits: 4) + " " + fromTokenData.symbol
  }

  @discardableResult
  func updateGasLimit(_ value: BigInt, platform: String, tokenAddress: String) -> Bool {
    if self.selectedPlatform == platform && self.toTokenData.address.lowercased() == tokenAddress.lowercased() {
      if self.selectedGasPriceType == .custom {
        self.baseGasLimit = value
      } else {
        self.gasLimit = value
        self.baseGasLimit = value
      }
      
      return true
    }
    return false
  }

  func buildSignSwapTx(_ object: TxObject) -> SignTransaction? {
    guard !KNGeneralProvider.shared.isUseEIP1559 else {
      return nil
    }
    guard
      let value = BigInt(object.value.drop0x, radix: 16),
      var gasPrice = BigInt(object.gasPrice.drop0x, radix: 16),
      var gasLimit = BigInt(object.gasLimit.drop0x, radix: 16),
      var nonce = Int(object.nonce.drop0x, radix: 16)
    else
    {
      return nil
    }
    
    if let unwrap = self.advancedMaxFee, let value = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      gasPrice = value
    }
    
    if let unwrap = self.advancedGasLimit, let value = BigInt(unwrap) {
      gasLimit = value
    }
    
    if let unwrap = self.advancedNonce, let value = Int(unwrap) {
      nonce = value
    }
    
    if currentAddress.isWatchWallet {
      return nil
    } else {
      return SignTransaction(
        value: value,
        address: currentAddress.addressString,
        to: object.to,
        nonce: nonce,
        data: Data(hex: object.data.drop0x),
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        chainID: KNGeneralProvider.shared.customRPC.chainID
      )
    }
    
  }

  func buildEIP1559Tx(_ object: TxObject) -> EIP1559Transaction? {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return nil
    }
    let gasLimitDefault = BigInt(object.gasLimit.drop0x, radix: 16) ?? self.gasLimit
    let gasPrice = BigInt(object.gasPrice.drop0x, radix: 16) ?? self.gasPrice
    let priorityFeeBigIntDefault = self.selectedPriorityFee
    let maxGasFeeDefault = gasPrice
    let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
    var nonce = object.nonce.hexSigned2Complement
    if let customNonceString = self.advancedNonce, let nonceInt = Int(customNonceString) {
      let nonceBigInt = BigInt(nonceInt)
      nonce = nonceBigInt.hexEncoded.hexSigned2Complement
    }
    if let advancedGasStr = self.advancedGasLimit,
       let gasLimit = BigInt(advancedGasStr),
       let priorityFeeString = self.advancedMaxPriorityFee,
       let priorityFee = priorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit),
       let maxGasFeeString = self.advancedMaxFee,
       let maxGasFee = maxGasFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFee.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
        toAddress: object.to,
        fromAddress: object.from,
        data: object.data,
        value: object.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    } else {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFeeDefault.hexEncoded.hexSigned2Complement,
        toAddress: object.to,
        fromAddress: object.from,
        data: object.data,
        value: object.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    }
  }

  var selectedPlatformData: LendingPlatformData {
    let selected = self.selectedPlatform
    let filtered = self.toTokenData.lendingPlatforms.first { (element) -> Bool in
      return element.name == selected
    }
    
    if let wrapped = filtered {
      return wrapped
    } else {
      return self.toTokenData.lendingPlatforms.first!
    }
  }
  
  private func isAmountChanged(amount: BigInt) -> Bool {
    guard let fromTokenData = fromTokenData else { return false }
    if self.amountFromBigInt == amount { return false }
    let doubleValue = Double(amount) / pow(10.0, Double(fromTokenData.decimals))
    return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
  }
  
  func getSwapRate(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged = isAmountChanged(amount: amount)

    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return ""
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      return element.platform == platform
    }
    return rateDict?.rate ?? ""
  }
  
  func getCurrentRateObj(platform: String) -> Rate? {
    let rateDict = self.swapRates.3.first { (element) -> Bool in
      return platform == element.platform
    }
    return rateDict
  }

  func resetSwapRates() {
    self.swapRates = ("", "", BigInt(0), [])
  }
  
  func getCurrentRate() -> BigInt? {
    guard let fromTokenData = fromTokenData else {
      return nil
    }

    let rateString: String = self.getSwapRate(from: fromTokenData.address.lowercased(), to: self.toTokenData.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    return BigInt(rateString)
  }
  
  var expectedReceivedAmountText: String {
    guard let fromTokenData = fromTokenData else {
      return ""
    }
    guard !self.amountFromBigInt.isZero else {
      return ""
    }
    let expectedRate = self.getCurrentRate() ?? BigInt(0)
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return expectedRate * amount * BigInt(10).power(self.toTokenData.decimals) / BigInt(10).power(18) / BigInt(10).power(fromTokenData.decimals)
    }()
    return expectedAmount.string(
      decimals: self.toTokenData.decimals,
      minFractionDigits: min(self.toTokenData.decimals, 5),
      maxFractionDigits: min(self.toTokenData.decimals, 5)
    ).removeGroupSeparator()
  }
  
  var expectedExchangeAmountText: String {
    guard let fromTokenData = fromTokenData else {
      return ""
    }
    guard !self.amountToBigInt.isZero else {
      return ""
    }
    let rate = self.getCurrentRate() ?? BigInt(0)
    let expectedExchange: BigInt = {
      if rate.isZero { return BigInt(0) }
      let amount = self.amountToBigInt * BigInt(10).power(18) * BigInt(10).power(fromTokenData.decimals)
      return amount / rate / BigInt(10).power(self.toTokenData.decimals)
    }()
    return expectedExchange.string(
      decimals: fromTokenData.decimals,
      minFractionDigits: fromTokenData.decimals,
      maxFractionDigits: fromTokenData.decimals
    ).removeGroupSeparator()
  }
  //TODO: buid display usd amount
//  var equivalentUSDAmount: BigInt? {
//    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.to) {
//      return usdRate.rate * self.amountToBigInt / BigInt(10).power(self.to.decimals)
//    }
//    return nil
//  }
//
//  var displayEquivalentUSDAmount: String? {
//    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
//    let value = amount.displayRate(decimals: 18)
//    return "~ $\(value) USD"
//  }
  func updateSwapRates(from: TokenData, to: TokenData, amount: BigInt, rates: [Rate]) {
    guard from == self.fromTokenData, to == self.toTokenData else {
      return
    }
    self.swapRates = (from.address.lowercased(), to.address.lowercased(), amount, rates)
  }
  
  func reloadBestPlatform() {
    let selectedGasPriceAmt = self.isFocusingFromAmount ? self.gasPriceSelectedAmount.0 : self.gasPriceSelectedAmount.1
    let amount = self.isFocusingFromAmount ? self.amountFrom : self.amountTo
    guard (amount != selectedGasPriceAmt) || selectedGasPriceAmt.isEmpty  else {
      return
    }
    let rates = self.swapRates.3
    if rates.count == 1 {
      let dict = rates.first
      self.currentFlatform = dict?.platform ?? ""
    } else {
      let max = rates.max { (left, right) -> Bool in
        if let leftBigInt = BigInt(left.rate), let rightBigInt = BigInt(right.rate) {
          return leftBigInt < rightBigInt
        } else {
          return false
        }
      }
      self.currentFlatform = max?.platform ?? ""
    }
  }

  var exchangeRateText: String? {
    if self.showingRevertRate {
      return self.displayRevertRate
    } else {
      return displayExchangeRate
    }
  }

  var displayExchangeRate: String? {
    guard let fromTokenData = fromTokenData else {
      return nil
    }

    let rateString: String = self.getSwapRate(from:fromTokenData.address.lowercased(), to: self.toTokenData.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    let rate = BigInt(rateString)
    if let notNilRate = rate {
      return notNilRate.isZero ? "---" : "Rate: 1 \(fromTokenData.symbol) = \(notNilRate.displayRate(decimals: 18)) \(self.toTokenData.symbol)"
    } else {
      return "---"
    }
  }
  
  var displayRevertRate: String? {
    guard let fromTokenData = fromTokenData else {
      return nil
    }
    let rateString: String = self.getSwapRate(from: fromTokenData.address.lowercased(), to: self.toTokenData.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    let rate = BigInt(rateString)
    if let notNilRate = rate, notNilRate != BigInt(0) {
      let revertRate = BigInt(10).power(36) / notNilRate
      return notNilRate.isZero ? "---" : "Rate: 1 \(self.toTokenData.symbol) = \(revertRate.displayRate(decimals: 18)) \(fromTokenData.symbol)"
    } else {
      return "---"
    }
  }
  
  func getRefPrice(from: TokenData, to: TokenData) -> String {
    guard let refPrice = refPrice, from == refPrice.from, to == refPrice.to else {
      return ""
    }
    return refPrice.priceString
  }
  
  var refPriceDiffText: String {
    guard let fromTokenData = fromTokenData else {
      return "---"
    }
    guard !self.getRefPrice(from: fromTokenData, to: self.toTokenData).isEmpty else {
      return "---"
    }
    let change = self.priceImpactValue
    let displayPercent = "\(change)".prefix(6)
    return "\(displayPercent)%"
  }
  
  var priceImpactValueTextColor: UIColor? {
    let change = self.priceImpactValue
    if change <= -5.0 {
      return UIColor(named: "textRedColor")
    } else if change <= -2.0 {
      return UIColor(named: "warningColor")
    } else {
      return UIColor(named: "textWhiteColor")
    }
  }
  
  func updateRefPrice(from: TokenData, to: TokenData, change: String, source: [String]) {
    guard from == self.fromTokenData, to == self.toTokenData else {
      return
    }
    self.refPrice = (from, to, change, source)
  }
  
  var slippageString: String {
    let doubleStr = String(format: "%.2f", self.minRatePercent)
    return "\(doubleStr)%"
  }

  var isUseGasToken: Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data[self.currentAddress.addressString] ?? false
  }

  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  var displayCompInfo: String {
    let comp = self.toTokenData.lendingPlatforms.first { item -> Bool in
      return item.isCompound
    }
    let symbol = KNGeneralProvider.shared.currentChain == .bsc ? "XVS" : "COMP"
    let apy = String(format: "%.2f", (comp?.distributionSupplyRate ?? 0.03) * 100.0)
    return "You will automatically earn \(symbol) token (\(apy)% APY) for interacting with \(comp?.name ?? "") (supply or borrow).\nOnce redeemed, \(symbol) token can be swapped to any token."
  }
  
  var equivalentUSDAmount: BigInt? {
    guard let fromTokenData = fromTokenData else {
      return nil
    }
    if let usdRate = KNTrackerRateStorage.shared.getPriceWithAddress(fromTokenData.address) {
      return self.amountFromBigInt * BigInt(usdRate.usd * pow(10.0, 18.0)) / BigInt(10).power(fromTokenData.decimals)
    }
    return nil
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }
  
  var gasFeeBigInt: BigInt {
    let fee = self.gasPrice * self.gasLimit
    return fee
  }
  
  var isHavingEnoughETHForFee: Bool {
    var fee = self.gasPrice * self.gasLimit
    guard let fromTokenData = fromTokenData else {
      return true
    }
    if fromTokenData.isQuoteToken { fee += self.amountFromBigInt }
    let ethBal = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return ethBal >= fee
  }
  
  var isCompound: Bool {
    return self.selectedPlatform == "Compound" || KNGeneralProvider.shared.currentChain == .bsc
  }
  
  var displayEstGas: String {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return ""
    }
    let baseFee = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let fee = (baseFee + self.selectedPriorityFee) * self.gasLimit
    let sourceToken = KNGeneralProvider.shared.quoteToken
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(sourceToken) "
  }
  
  var selectedPriorityFee: BigInt {
    switch self.selectedGasPriceType {
    case .slow:
      return KNGasCoordinator.shared.lowPriorityFee ?? BigInt(0)
    case .medium:
      return KNGasCoordinator.shared.standardPriorityFee ?? BigInt(0)
    case .fast:
      return KNGasCoordinator.shared.fastPriorityFee ?? BigInt(0)
    case .superFast:
      return KNGasCoordinator.shared.superFastPriorityFee ?? BigInt(0)
    case .custom:
      if let unwrap = self.advancedMaxPriorityFee, let fee = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
        return fee
      } else {
        return BigInt(0)
      }
    }
  }
  
  typealias SwapValidationError = (title: String, message: String)
  
  func validate(isConfirming: Bool) -> ValidationResult<SwapValidationError> {
    guard let fromTokenData = fromTokenData else {
      return isConfirming
      ? .failure(error: (title: Strings.invalidInput, message: Strings.pleaseSelectSourceToken))
      : .success
    }

    let estRate = getSwapRate(from: fromTokenData.address.lowercased(),
                              to: toTokenData.address.lowercased(),
                              amount: amountFromBigInt,
                              platform: currentFlatform)
    let estRateBigInt = BigInt(estRate)
    if estRateBigInt?.isZero == true {
      return .failure(error: (title: "", message: Strings.canNotFindExchangeRate))
    }
    guard fromTokenData.address != self.toTokenData.address else {
      return .failure(error: (title: Strings.unsupported, message: Strings.canNotSwapSameToken))
    }
    guard !self.amountTo.isEmpty else {
      return .failure(error: (title: Strings.invalidInput, message: Strings.pleaseEnterAmountToContinue))
    }
    guard !self.isAmountTooSmall else {
      return .failure(error: (title: Strings.invalidAmount, message: Strings.amountToSendGreaterThanZero))
    }
    guard !self.isAmountTooBig else {
      return .failure(error: (title: Strings.amountTooBig, message: Strings.balanceNotEnoughToMakeTransaction))
    }
    if isConfirming {
      guard self.isHavingEnoughETHForFee else {
        let fee = self.gasFeeBigInt
        let title = String(format: Strings.insufficientXForTransaction.toBeLocalised(), KNGeneralProvider.shared.quoteToken)
        let message = String(format: Strings.depositMoreXOrClickAdvancedToLowerGasFee.toBeLocalised(), fee.shortString(units: .ether, maxFractionDigits: 6))
        return .failure(error: (title: title, message: message))
      }
    }
    return .success
  }
  
}

class EarnSwapViewController: KNBaseViewController, AbstractEarnViewControler {
  @IBOutlet weak var platformTableView: UITableView!
  @IBOutlet weak var toAmountTextField: UITextField!
  @IBOutlet weak var selectedGasFeeLabel: UILabel!
  @IBOutlet weak var platformTableViewHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var compInfoMessageContainerView: UIView!
  @IBOutlet weak var sendButtonTopContraint: NSLayoutConstraint!
  @IBOutlet weak var earnButton: UIButton!
  @IBOutlet weak var fromTokenButton: UIButton!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var fromAmountTextField: UITextField!
  @IBOutlet weak var maxFromAmountButton: UIButton!
  @IBOutlet weak var equivalentUSDValueLabel: UILabel!
  @IBOutlet weak var fromAmountFieldTrailing: NSLayoutConstraint!
  @IBOutlet weak var exchangeRateLabel: UILabel!
  @IBOutlet weak var rateWarningLabel: UILabel!
  @IBOutlet weak var changeRateButton: UIButton!
  @IBOutlet weak var walletsSelectButton: UIButton!
  @IBOutlet weak var slippageLabel: UILabel!
  @IBOutlet weak var approveButtonLeftPaddingContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonRightPaddingContaint: NSLayoutConstraint!
  @IBOutlet weak var approveButton: UIButton!
  @IBOutlet weak var approveButtonEqualWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var toTokenButton: UIButton!
  @IBOutlet weak var selectDepositTitleLabel: UILabel!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var compInfoLabel: UILabel!
  @IBOutlet weak var minReceivedAmount: UILabel!
  @IBOutlet weak var estGasFeeTitleLabel: UILabel!
  @IBOutlet weak var estGasFeeValueLabel: UILabel!
  @IBOutlet weak var rateBlockerView: UIView!
  @IBOutlet weak var gasAndFeeBlockerView: UIView!
  @IBOutlet weak var gasFeeTittleLabelTopContraint: NSLayoutConstraint!
  @IBOutlet weak var destAmountContainerView: UIView!
  
  let viewModel: EarnSwapViewModel
  //flag to check if should open confirm screen right after done edit transaction setting
  fileprivate var shouldOpenConfirm: Bool = false
  fileprivate var isViewSetup: Bool = false
  fileprivate var isViewDisappeared: Bool = false
  weak var delegate: EarnViewControllerDelegate?
  fileprivate var estRateTimer: Timer?
  fileprivate var estGasLimitTimer: Timer?
  weak var navigationDelegate: NavigationBarDelegate?

  init(viewModel: EarnSwapViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnSwapViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let nib = UINib(nibName: EarnSelectTableViewCell.className, bundle: nil)
    self.platformTableView.register(
      nib,
      forCellReuseIdentifier: EarnSelectTableViewCell.kCellID
    )
    self.platformTableView.rowHeight = EarnSelectTableViewCell.kCellHeight
    self.platformTableViewHeightContraint.constant = CGFloat(self.viewModel.platformDataSource.count) * EarnSelectTableViewCell.kCellHeight
    self.updateInforMessageUI()
    self.earnButton.setTitle("Next".toBeLocalised(), for: .normal)
    self.updateGasFeeUI()
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.toTokenButton.setTitle(self.viewModel.toTokenData.symbol.uppercased(), for: .normal)
    self.updateUITokenDidChange(self.viewModel.fromTokenData)
    self.resetBalanceValues()
    self.updateUIWalletSelectButton()
    self.setUpGasFeeView()
    self.setupHideRateAndFeeViews(shouldHideInfo: true)
    self.destAmountContainerView.rounded(color: UIColor(named: "toolbarBgColor")!, width: 2, radius: 16)
    self.fromAmountTextField.setupCustomDeleteIcon()
    self.toAmountTextField.setupCustomDeleteIcon()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.isViewSetup = true
    self.isViewDisappeared = false
    self.updateUIPendingTxIndicatorView()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Tracker.track(event: .openEarnSwapView)
    self.updateAllRates()
    self.estRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds30,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.updateAllRates()
      }
    )
    self.updateGasLimit()
    self.estGasLimitTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds60,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.updateGasLimit()
      }
    )
    self.updateRefPrice()
    self.updateAllowance()
    self.updateUIBalanceDidChange()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isViewDisappeared = true
    self.view.endEditing(true)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.estRateTimer?.invalidate()
    self.estRateTimer = nil
    self.estGasLimitTimer?.invalidate()
    self.estGasLimitTimer = nil
  }
  
  func resetBalanceValues() {
    balanceLabel.text = nil
    equivalentUSDValueLabel.text = nil
  }

  fileprivate func updateInforMessageUI() {
    if self.viewModel.isCompound {
      self.compInfoLabel.text = self.viewModel.displayCompInfo
      self.compInfoMessageContainerView.isHidden = false
      self.sendButtonTopContraint.constant = 150
    } else {
      self.compInfoMessageContainerView.isHidden = true
      self.sendButtonTopContraint.constant = 30
    }
  }

  func updateGasLimit() {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    let event = EarnViewEvent.getGasLimit(
      lendingPlatform: self.viewModel.selectedPlatform,
      src: fromTokenData.address,
      dest: self.viewModel.toTokenData.address,
      srcAmount: self.viewModel.amountToBigInt.description,
      minDestAmount: self.viewModel.minDestQty.description,
      gasPrice: self.viewModel.gasPrice.description,
      isSwap: true
    )
    self.delegate?.earnViewController(self, run: event)
  }

  func buildTx() {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    let event = EarnViewEvent.buildTx(
      lendingPlatform: self.viewModel.selectedPlatform,
      src: fromTokenData.address,
      dest: self.viewModel.toTokenData.address,
      srcAmount: self.viewModel.amountFromBigInt.description,
      minDestAmount: self.viewModel.minDestQty.description,
      gasPrice: self.viewModel.gasPrice.description,
      isSwap: true
    )
    self.delegate?.earnViewController(self, run: event)
  }

  fileprivate func updateRefPrice() {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    self.delegate?.earnViewController(self, run: .getRefPrice(from: fromTokenData, to: self.viewModel.toTokenData))
  }

  fileprivate func updateAmountFieldUIForTransferAllETHIfNeeded() {
    //TODO: uncommemnt after add from field outlet
  }
  
  fileprivate func updateExchangeRateField() {
    self.exchangeRateLabel.text = self.viewModel.exchangeRateText
  }

  fileprivate func updateUIMinReceiveAmount() {
    self.minReceivedAmount.text = self.viewModel.displayMinDestAmount
  }

  fileprivate func updateGasFeeUI() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
    if KNGeneralProvider.shared.isUseEIP1559 {
      self.estGasFeeTitleLabel.isHidden = false
      self.estGasFeeValueLabel.isHidden = false
      self.gasFeeTittleLabelTopContraint.constant = 54
    } else {
      self.estGasFeeTitleLabel.isHidden = true
      self.estGasFeeValueLabel.isHidden = true
      self.gasFeeTittleLabelTopContraint.constant = 20
    }
    self.estGasFeeValueLabel.text = self.viewModel.displayEstGas
  }

  fileprivate func updateUIRefPrice() {
    self.rateWarningLabel.text = self.viewModel.refPriceDiffText
    self.rateWarningLabel.textColor = self.viewModel.priceImpactValueTextColor
  }

  fileprivate func updateApproveButton() {
    guard let fromTokenData = viewModel.fromTokenData else {
      return
    }
    self.approveButton.setTitle("Approve".toBeLocalised() + " " + fromTokenData.symbol, for: .normal)
  }

  fileprivate func updateUIWalletSelectButton() {
    guard self.isViewLoaded else {
      return
    }
    self.walletsSelectButton.setTitle(self.viewModel.currentAddress.name, for: .normal)
  }

  fileprivate func updateUIForSendApprove(isShowApproveButton: Bool, token: TokenObject? = nil) {
    guard self.isViewLoaded else {
      return
    }
    if let unwrapped = token, let fromTokenData = viewModel.fromTokenData, unwrapped.contract.lowercased() != fromTokenData.address.lowercased() {
      return
    }
    self.updateApproveButton()
    if isShowApproveButton {
      self.approveButtonLeftPaddingContraint.constant = 37
      self.approveButtonRightPaddingContaint.constant = 15
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 999)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.earnButton.isEnabled = false
      self.earnButton.alpha = 0.2
      if self.viewModel.approvingToken == nil {
        self.approveButton.isEnabled = true
        self.approveButton.alpha = 1
      } else {
        self.approveButton.isEnabled = false
        self.approveButton.alpha = 0.2
      }
    } else {
      self.approveButtonLeftPaddingContraint.constant = 0
      self.approveButtonRightPaddingContaint.constant = 37
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 999)
      self.earnButton.isEnabled = true
      self.earnButton.alpha = 1
    }
    self.view.layoutIfNeeded()
  }

  fileprivate func setUpChangeRateButton() {
    guard let rate = self.viewModel.getCurrentRateObj(platform: self.viewModel.currentFlatform)  else {
      self.changeRateButton.setImage(nil, for: .normal)
      return
    }
    let url = URL(string: rate.platformIcon)
    self.changeRateButton.kf.setImage(with: url, for: .normal, completionHandler: { result in
      switch result {
      case .success(let image):
        let resized = image.image.resizeImage(to: CGSize(width: 16, height: 16))
        self.changeRateButton.setImage(resized, for: .normal)
      case .failure(_):
        break
      }
    })
    self.changeRateButton.setTitle(rate.platformShort, for: .normal)
  }

  fileprivate func setUpGasFeeView() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
    self.slippageLabel.text = self.viewModel.slippageString
  }

  fileprivate func setupHideRateAndFeeViews(shouldHideInfo: Bool) {
    self.gasAndFeeBlockerView.isHidden = !shouldHideInfo
    self.rateBlockerView.isHidden = !shouldHideInfo
  }

  fileprivate func updateAllowance() {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    guard !(fromTokenData.isWrapToken && self.viewModel.toTokenData.isQuoteToken) else { return }
    self.delegate?.earnViewController(self, run: .checkAllowance(token: fromTokenData))
  }

  @IBAction func warningRateButtonTapped(_ sender: UIButton) {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    guard !self.viewModel.refPriceDiffText.isEmpty else { return }
    var message = ""
    if self.viewModel.getRefPrice(from: fromTokenData, to: self.viewModel.toTokenData).isEmpty {
      message = " Missing price impact. Please swap with caution."
    } else {
      message = String(format: KNGeneralProvider.shared.priceAlertMessage.toBeLocalised(), self.viewModel.refPriceDiffText)
    }
    self.showTopBannerView(
      with: "",
      message: message,
      icon: UIImage(named: "info_blue_icon"),
      time: 5.0
    )
  }
  
  @IBAction func gasFeeAreaTapped(_ sender: UIButton) {
    self.shouldOpenConfirm = false
    self.openTransactionSetting()
  }
  
  fileprivate func openTransactionSetting() {
    self.delegate?.earnViewController(self, run: .openGasPriceSelect(
      gasLimit: self.viewModel.gasLimit,
      baseGasLimit: self.viewModel.baseGasLimit,
      selectType: self.viewModel.selectedGasPriceType,
      isSwap: true,
      minRatePercent: self.viewModel.minRatePercent,
      advancedGasLimit: self.viewModel.advancedGasLimit,
      advancedPriorityFee: self.viewModel.advancedMaxPriorityFee,
      advancedMaxFee: self.viewModel.advancedMaxFee,
      advancedNonce: self.viewModel.advancedNonce
    ))
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func changeRateButtonTapped(_ sender: UIButton) {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    let rates = self.viewModel.swapRates.3
    if rates.count >= 2 {
      self.delegate?.earnViewController(self, run: .openChooseRate(from: fromTokenData, to: self.viewModel.toTokenData, rates: rates, gasPrice: self.viewModel.gasPrice, amountFrom: self.viewModel.amountFrom))
    }
  }
  
  @IBAction func maxAmountButtonTapped(_ sender: UIButton) {
    self.balanceLabelTapped(sender)
  }

  @IBAction func approveButtonTapped(_ sender: UIButton) {
    guard let remain = self.viewModel.remainApprovedAmount else {
      return
    }
    self.delegate?.earnViewController(self, run: .sendApprove(token: remain.0, remain: remain.1))
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    self.openSwapConfirm()
  }
  
  fileprivate func openSwapConfirm() {
    guard !self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) else {
      return
    }
    self.buildTx()
  }
  
  @IBAction func fromTokenButtonTapped(_ sender: UIButton) {
    self.delegate?.earnViewController(self, run: .searchToken(isSwap: true))
  }
  
  @objc func balanceLabelTapped(_ sender: Any) {
    self.keyboardSwapAllButtonPressed(sender)
  }
  
  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }

  @IBAction func walletsButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }

  @IBAction func revertRateButtonTapped(_ sender: UIButton) {
    self.viewModel.showingRevertRate = !self.viewModel.showingRevertRate
    self.updateExchangeRateField()
  }

  func keyboardSwapAllButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.viewModel.updateFocusingField(true)
    guard let fromTokenData = viewModel.fromTokenData else { return }
    self.fromAmountTextField.text = self.viewModel.allTokenBalanceString?.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true, forSendAllETH: fromTokenData.isQuoteToken)
    self.updateViewAmountDidChange()
    self.updateAllRates()
    if sender as? KSwapViewController != self {
      if fromTokenData.isQuoteToken {
        self.showSuccessTopBannerMessage(
          with: "",
          message: "A small amount of \(KNGeneralProvider.shared.quoteToken) will be used for transaction fee",
          time: 1.5
        )
      }
    }
    self.viewModel.isSwapAllBalance = true
    self.view.layoutIfNeeded()
  }

  func coordinatorEditTransactionSetting() {
    self.shouldOpenConfirm = true
    self.openTransactionSetting()
  }

  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.updateAmountFieldUIForTransferAllETHIfNeeded()
    self.updateGasFeeUI()
    self.updateGasLimit()
    self.viewModel.resetAdvancedSettings()
    if self.shouldOpenConfirm {
      self.openSwapConfirm()
      self.shouldOpenConfirm = false
    }
  }

  func coordinatorDidUpdateGasLimit(_ value: BigInt, platform: String, tokenAdress: String) {
    if self.viewModel.updateGasLimit(value, platform: platform, tokenAddress: tokenAdress) {
      self.updateAmountFieldUIForTransferAllETHIfNeeded()
      self.updateGasFeeUI()
    } else {
      self.updateGasLimit()
    }
  }

  func coordinatorFailUpdateGasLimit() {
    self.updateGasLimit()
  }
  
  func coordinatorDidUpdateSuccessTxObject(txObject: TxObject) {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    let tx = self.viewModel.buildSignSwapTx(txObject)
    let eip1559Tx = self.viewModel.buildEIP1559Tx(txObject)
    let priceImpactValue = self.viewModel.getRefPrice(from: fromTokenData, to: self.viewModel.toTokenData).isEmpty ? -1000.0 : self.viewModel.priceImpactValue
    let event = EarnViewEvent.confirmTx(
      fromToken: fromTokenData,
      toToken: self.viewModel.toTokenData,
      platform: self.viewModel.selectedPlatformData,
      fromAmount: self.viewModel.amountFromBigInt,
      toAmount: self.viewModel.amountToBigInt,
      gasPrice: self.viewModel.gasPrice,
      gasLimit: self.viewModel.gasLimit,
      transaction: tx,
      eip1559Transaction: eip1559Tx,
      isSwap: true,
      rawTransaction: txObject,
      minReceiveDest: (self.viewModel.displayExpectedReceiveTitle, self.viewModel.displayExpectedReceiveValue),
      priceImpact: priceImpactValue,
      maxSlippage: self.viewModel.minRatePercent
    )
    self.delegate?.earnViewController(self, run: event)
  }
  
  func coordinatorFailUpdateTxObject(error: Error) {
    self.navigationController?.showErrorTopBannerMessage(with: error.localizedDescription)
  }
  
  func coordinatorDidUpdateRates(from: TokenData, to: TokenData, srcAmount: BigInt, rates: [Rate]) {
    self.viewModel.updateSwapRates(from: from, to: to, amount: srcAmount, rates: rates)
    self.viewModel.reloadBestPlatform()
    self.updateExchangeRateField()
    self.setUpChangeRateButton()
    self.updateUIRefPrice()
    self.updateInputFieldsUI()
    self.updateUIMinReceiveAmount()
  }

  func coordinatorFailUpdateRates() {
    //TODO: show error loading rate if needed on UI
  }
  
  func coordinatorDidUpdatePlatform(_ platform: String) {
    self.viewModel.currentFlatform = platform
    self.viewModel.gasPriceSelectedAmount = (self.viewModel.amountFrom, self.viewModel.amountTo)
    self.setUpChangeRateButton()
    self.updateExchangeRateField()
    self.updateInputFieldsUI()
    self.updateGasFeeUI()
    self.updateGasLimit()
  }
  
  func coordinatorSuccessUpdateRefPrice(from: TokenData, to: TokenData, change: String, source: [String]) {
    self.viewModel.updateRefPrice(from: from, to: to, change: change, source: source)
    self.updateUIRefPrice()
  }
  
  func coordinatorDidUpdateMinRatePercentage(_ value: CGFloat) {
    self.viewModel.updateExchangeMinRatePercent(Double(value))
    self.setUpGasFeeView()
    self.updateUIMinReceiveAmount()
  }
  
  func updateUIBalanceDidChange() {
    guard self.isViewSetup else {
      return
    }
    self.balanceLabel.text = self.viewModel.totalBalanceText
  }
  
  fileprivate func updateUITokenDidChange(_ token: TokenData?) {
    if let token = token {
      self.maxFromAmountButton.isHidden = false
      self.fromAmountFieldTrailing.constant = 8
      self.fromTokenButton.setTitle(token.symbol.uppercased(), for: .normal)
      self.fromTokenButton.setTitleColor(.white, for: .normal)
      self.selectDepositTitleLabel.text = String(format: Strings.selectPlatformToSupply, self.viewModel.toTokenData.symbol.uppercased())
      self.updateRefPrice()
    } else {
      self.fromAmountFieldTrailing.constant = -30
      self.maxFromAmountButton.isHidden = true
      self.fromTokenButton.setTitle(Strings.selectToken, for: .normal)
      self.fromTokenButton.setTitleColor(.white.withAlphaComponent(0.5), for: .normal)
    }
  }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    let pendingTransaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().first { transaction in
      transaction.state == .pending
    }
    self.pendingTxIndicatorView.isHidden = pendingTransaction == nil
  }

  func coordinatorUpdateIsUseGasToken(_ state: Bool) {
  }

  func coordinatorDidUpdateAllowance(token: TokenData, allowance: BigInt) {
    guard let fromTokenData = self.viewModel.fromTokenData, !fromTokenData.isQuoteToken else {
      self.updateUIForSendApprove(isShowApproveButton: false)
      return
    }
    if fromTokenData.getBalanceBigInt() > allowance {
      self.viewModel.remainApprovedAmount = (token, allowance)
      self.updateUIForSendApprove(isShowApproveButton: true, token: token.toObject())
    } else {
      self.updateUIForSendApprove(isShowApproveButton: false)
    }
  }

  func coordinatorDidFailUpdateAllowance(token: TokenData) {
    //TODO: handle error
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
    self.checkUpdateApproveButton()
    self.updateUIBalanceDidChange()
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.updateUIBalanceDidChange()
  }

  func coordinatorSuccessApprove(token: TokenObject) {
    self.viewModel.approvingToken = token
    self.updateUIForSendApprove(isShowApproveButton: true, token: token)
  }

  func coordinatorFailApprove(token: TokenObject) {
    self.showErrorMessage()
    self.updateUIForSendApprove(isShowApproveButton: true, token: token)
  }
  
  fileprivate func showErrorMessage() {
    self.showWarningTopBannerMessage(
      with: "",
      message: "Something went wrong, please try again later".toBeLocalised(),
      time: 2.0
    )
  }
  
  fileprivate func checkUpdateApproveButton() {
    guard let token = self.viewModel.approvingToken else {
      return
    }
    if EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty {
      self.updateUIForSendApprove(isShowApproveButton: false)
      self.viewModel.approvingToken = nil
    }
    let pending = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().filter({ (item) -> Bool in
      return item.transactionDetailDescription.lowercased() == token.address.lowercased() && item.type == .allowance
    })
    if pending.isEmpty {
      self.updateUIForSendApprove(isShowApproveButton: false)
      self.viewModel.approvingToken = nil
    }
  }

  func coordinatorUpdateSelectedToken(_ token: TokenData) {
    self.viewModel.resetAdvancedSettings()
    self.viewModel.showingRevertRate = false
    self.viewModel.updateFromToken(token)
    self.updateUITokenDidChange(self.viewModel.fromTokenData)
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.equivalentUSDValueLabel.text = nil
    self.rateBlockerView.isHidden = false
    if self.viewModel.fromTokenData == self.viewModel.toTokenData {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: NSLocalizedString("can.not.swap.same.token", value: "Can not swap the same token", comment: ""),
        time: 1.5
      )
    }
    self.viewModel.gasPriceSelectedAmount = ("", "")
    self.updateUIBalanceDidChange()
    self.updateApproveButton()
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.updateGasLimit()
    self.updateAllowance()
    self.updateAllRates()
    self.updateUIMinReceiveAmount()
    self.updateGasFeeUI()
  }

  func coordinatorAppSwitchAddress() {
    if self.isViewSetup {
      self.updateUIBalanceDidChange()
      self.updateUIWalletSelectButton()
      self.updateUIWalletSelectButton()
      self.updateUIPendingTxIndicatorView()
    }
  }

  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.updateSelectedGasPriceType(.custom)
    self.updateGasFeeUI()
    if self.shouldOpenConfirm {
      self.openSwapConfirm()
      self.shouldOpenConfirm = false
    }
  }

  func coordinatorSuccessSendTransaction() {
    self.viewModel.advancedGasLimit = nil
    self.viewModel.advancedMaxPriorityFee = nil
    self.viewModel.advancedMaxFee = nil
    self.viewModel.updateSelectedGasPriceType(.medium)
    self.updateGasFeeUI()
    self.viewModel.resetAdvancedSettings()
  }

  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }
}

extension EarnSwapViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.platformDataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: EarnSelectTableViewCell.kCellID,
      for: indexPath
    ) as! EarnSelectTableViewCell
    let cellViewModel = self.viewModel.platformDataSource[indexPath.row]
    cell.updateCellViewViewModel(cellViewModel)
    return cell
  }
}

extension EarnSwapViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellViewModel = self.viewModel.platformDataSource[indexPath.row]
    self.viewModel.platformDataSource.forEach { (element) in
      element.isSelected = false
    }
    cellViewModel.isSelected = true
    tableView.reloadData()
    self.updateGasLimit()
    self.updateInforMessageUI()
  }
}

extension EarnSwapViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.viewModel.updateAmount("", isSource: textField != self.toAmountTextField)
    self.viewModel.isSwapAllBalance = false
    self.updateViewAmountDidChange()
    self.updateAllRates()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let cleanedText = text.cleanStringToNumber()
    if textField == self.fromAmountTextField, let fromTokenData = viewModel.fromTokenData, cleanedText.amountBigInt(decimals: fromTokenData.decimals) == nil { return false }
    if textField == self.toAmountTextField && cleanedText.amountBigInt(decimals: self.viewModel.toTokenData.decimals) == nil { return false }
    let double: Double = {
      if textField == self.fromAmountTextField, let fromTokenData = viewModel.fromTokenData {
        let bigInt = Double(text.amountBigInt(decimals: fromTokenData.decimals) ?? BigInt(0))
        return Double(bigInt) / pow(10.0, Double(fromTokenData.decimals))
      } else if textField == self.toAmountTextField {
        let bigInt = Double(text.amountBigInt(decimals: self.viewModel.toTokenData.decimals) ?? BigInt(0))
        return Double(bigInt) / pow(10.0, Double(self.viewModel.toTokenData.decimals))
      }
      return 0
    }()
    textField.text = text
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.viewModel.updateAmount(text, isSource: textField == self.fromAmountTextField)
    self.updateAllRates()
    self.updateViewAmountDidChange()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.isSwapAllBalance = false
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.updateViewAmountDidChange()
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    _ = self.showWarningInvalidAmountDataIfNeeded()
    self.updateGasLimit()
    self.updateAllRates()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = self.showWarningInvalidAmountDataIfNeeded()
    }
  }

  fileprivate func showWarningInvalidAmountDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming && self.isViewDisappeared { return false }
    
    let validationResult = viewModel.validate(isConfirming: isConfirming)
    
    switch validationResult {
    case .success:
      return false
    case .failure(let error):
      showWarningTopBannerMessage(with: error.title, message: error.message)
      return true
    }
  }

  fileprivate func updateViewAmountDidChange() {
    self.updateInputFieldsUI()
    self.updateExchangeRateField()
    self.updateUIMinReceiveAmount()
  }

  fileprivate func updateInputFieldsUI() {
    if self.viewModel.isFocusingFromAmount {
      self.toAmountTextField.text = self.viewModel.expectedReceivedAmountText
      self.viewModel.updateAmount(self.toAmountTextField.text ?? "", isSource: false)
    } else {
      self.fromAmountTextField.text = self.viewModel.expectedExchangeAmountText
      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    }
    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount
    let shouldHideInfo = self.viewModel.expectedReceivedAmountText.isEmpty && self.viewModel.expectedExchangeAmountText.isEmpty
    self.setupHideRateAndFeeViews(shouldHideInfo: shouldHideInfo)
  }

  fileprivate func updateAllRates() {
    guard let fromTokenData = viewModel.fromTokenData else { return }
    let amount = self.viewModel.isFocusingFromAmount ? self.viewModel.amountFromBigInt : self.viewModel.amountToBigInt
    let event = EarnViewEvent.getAllRates(from: fromTokenData, to: self.viewModel.toTokenData, amount: amount, focusSrc: self.viewModel.isFocusingFromAmount)
    self.delegate?.earnViewController(self, run: event)
  }
}
