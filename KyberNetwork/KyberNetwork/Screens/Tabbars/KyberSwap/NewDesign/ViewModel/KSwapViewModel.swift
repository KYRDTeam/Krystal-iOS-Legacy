// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustCore

struct RawSwapTransaction {
  let userAddress: String
  let src: String
  let dest: String
  let srcQty: String
  let minDesQty: String
  let gasPrice: String
  let nonce: Int
  let hint: String
  let useGasToken: Bool
}

class KSwapViewModel {  
  let defaultTokenIconImg = UIImage(named: "default_token")
  let eth = KNSupportedTokenStorage.shared.getETH().toObject()
  let knc = KNSupportedTokenStorage.shared.getKNC().toObject()

  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate var supportedTokens: [TokenObject] = []

  fileprivate(set) var from: TokenObject?
  fileprivate(set) var to: TokenObject?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var estRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?
  fileprivate(set) var minRatePercent: Double = 0.5

  var isSwapAllBalance: Bool = false
  var isTappedSwapAllBalance: Bool = false

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas

  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault
  fileprivate(set) var baseGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault
  var swapRates: (String, String, BigInt, [Rate]) = ("", "", BigInt(0), [])
  var currentFlatform: String = "Kyber" {
    didSet {
      let dict = self.swapRates.3.first { (element) -> Bool in
        return element.platform == self.currentFlatform
      }
      if self.estimateGasLimit == KNGasConfiguration.exchangeTokensGasLimitDefault {
        self.estimateGasLimit = BigInt(dict?.estimatedGas ?? 0)
      }
    }
  }
  var remainApprovedAmount: (TokenObject, BigInt)?
  var latestNonce: Int = 0
  var refPrice: (from: TokenObject, to: TokenObject, price: String, sources: [String])?
  var gasPriceSelectedAmount: (String, String) = ("", "")
  var approvingToken: TokenObject?
  var showingRevertedRate: Bool = false
  var isFromDeepLink: Bool = false
  var advancedGasLimit: String?
  var advancedMaxPriorityFee: String?
  var advancedMaxFee: String?
  var advancedNonce: String?

  init(wallet: Wallet,
       from: TokenObject,
       to: TokenObject,
       supportedTokens: [TokenObject]
    ) {
    self.wallet = wallet
    let addr = wallet.addressString
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr)?.clone() ?? KNWalletObject(address: addr)
    self.from = from.clone()
    self.to = to.clone()
    self.supportedTokens = supportedTokens.map({ return $0.clone() })
  }
  // MARK: Wallet name
  var walletNameString: String {
    let address = self.walletObject.address.lowercased()
    return "|  \(address.prefix(10))...\(address.suffix(8))"
  }

  // MARK: From Token
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.estimateGasLimit
  }

  var isUseGasToken: Bool {
    return false
  }

  var allFromTokenBalanceString: String? {
    guard let from = from else { return nil }
    if from.isQuoteToken {
      let balance = from.getBalanceBigInt()
      if balance <= self.feeBigInt { return "0" }
      let fee = self.allETHBalanceFee
      let availableToSwap = max(BigInt(0), balance - fee)
      let string = availableToSwap.string(
        decimals: from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(from.decimals, 5)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.balanceText?.removeGroupSeparator()
  }

  var fromAmount: BigInt {
    guard let decimals = from?.decimals else { return BigInt(0) }
    return self.amountFrom.removeGroupSeparator().amountBigInt(decimals: decimals) ?? BigInt(0)
  }

  var estimatedDestAmount: BigInt {
    guard let from = from else { return BigInt(0) }
    
    if self.fromAmount.isZero, let smallAmount = EtherNumberFormatter.short.number(from: "0.001", decimals: from.decimals) {
      return smallAmount
    }
    return self.fromAmount
  }

  private var equivalentUSDAmount: BigInt? {
    guard let from = from, let price = KNTrackerRateStorage.shared.getPriceWithAddress(from.address) else {
      return nil
    }
    return equivalentUSDAmount(amount: fromAmount,
                               usdRate: price.usd,
                               decimals: from.decimals)
  }
  
  private func equivalentUSDAmount(amount: BigInt, usdRate: Double, decimals: Int) -> BigInt {
    return amount * BigInt(usdRate * pow(10.0, 18.0)) / BigInt(10).power(decimals)
  }
  
  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let valueString = amount.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: DecimalNumber.usd)
    if let doubleValue = Double(valueString), doubleValue < 0.01 {
      return ""
    }
    return "~ $\(valueString) USD"
  }

  var fromTokenIconName: String? {
    return self.from?.icon
  }

  var isFromTokenBtnEnabled: Bool {
    guard KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) != nil else {
      // not a promo wallet, always enabled
      return true
    }
    if from?.isPromoToken ?? false {
      return false
    }
    return true
  }

  var fromTokenSymbol: String? {
    return self.from?.symbol
  }
  
  var isFromTokenSelected: Bool {
    return from != nil
  }

  // when user wants to fix received amount
  var expectedExchangeAmountText: String? { //TODO: Improve loading rate later
    guard let from = from, let to = to else {
      return nil
    }
    guard !self.toAmount.isZero else {
      return ""
    }
    let rate = exchangeRate ?? BigInt(0)
    let expectedExchange: BigInt = {
      if rate.isZero { return BigInt(0) }
      let amount = self.toAmount * BigInt(10).power(18) * BigInt(10).power(from.decimals)
      return amount / rate / BigInt(10).power(to.decimals)
    }()
    return expectedExchange.string(
      decimals: from.decimals,
      minFractionDigits: from.decimals,
      maxFractionDigits: from.decimals
    ).removeGroupSeparator()
  }

  // MARK: To Token
  var toAmount: BigInt {
    guard let to = to else { return BigInt(0) }
    return self.amountTo.removeGroupSeparator().amountBigInt(decimals: to.decimals) ?? BigInt(0)
  }

  var isToTokenBtnEnabled: Bool {
    guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) else {
      // not a promo wallet, always enabled
      return true
    }
    
    if (from?.isPromoToken ?? false) && (to?.symbol == destToken) { return false }
    return true
  }

  var toTokenSymbol: String? {
    return self.to?.symbol
  }

  var toTokenIconName: String? {
    return self.to?.icon
  }
  
  var isToTokenSelected: Bool {
    return to != nil
  }

  var amountTextFieldColor: UIColor {
    return self.isAmountValid ? UIColor.Kyber.enygold : UIColor.red
  }

  var expectedReceivedAmountText: String {
    guard let from = from, let to = to else {
      return ""
    }
    guard !self.fromAmount.isZero else {
      return ""
    }

    let expectedRate = exchangeRate ?? BigInt(0)
    let expectedAmount: BigInt = {
      let amount = self.fromAmount
      return expectedRate * amount * BigInt(10).power(to.decimals) / BigInt(10).power(18) / BigInt(10).power(from.decimals)
    }()
    return expectedAmount.string(
      decimals: to.decimals,
      minFractionDigits: min(to.decimals, 5),
      maxFractionDigits: min(to.decimals, 5)
    ).removeGroupSeparator()
  }

  // MARK: Balance
  private var balanceText: String? {
    guard let from = from else { return nil }
    let bal: BigInt = from.getBalanceBigInt()
    let string = bal.string(
      decimals: from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(from.decimals, 5)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }
  
  var balanceDisplayText: String? {
    guard let balanceText = balanceText, let fromSymbol = from?.symbol else {
      return nil
    }
    return "\(balanceText) \(fromSymbol)"
  }

  // MARK: Rate
  var exchangeRateText: String? {
    guard let from = from, let to = to else {
      return nil
    }
    
    guard let rate = exchangeRate, !rate.isZero else {
      return "---"
    }
    
    if showingRevertedRate {
      return "Rate: 1 \(from.symbol) = \(rate.displayRate(decimals: 18)) \(to.symbol)"
    } else {
      let revertRate = BigInt(10).power(36) / rate
      return "Rate: 1 \(to.symbol) = \(revertRate.displayRate(decimals: 18)) \(from.symbol)"
    }
  }
  
  private var exchangeRate: BigInt? {
    guard let from = from, let to = to else { return nil }
    
    let rateString = self.getSwapRate(
      from: from.address.lowercased(),
      to: to.address.lowercased(),
      amount: fromAmount,
      platform: currentFlatform
    )
    return BigInt(rateString)
  }

  var minRate: BigInt? {
    guard let estRate = self.estRate else { return nil }
    return estRate * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var slippageRateText: String? {
    guard let to = to else { return nil }
    return self.slippageRate?.string(decimals: to.decimals, minFractionDigits: 0, maxFractionDigits: min(to.decimals, 9))
  }

  // MARK: Gas Price
  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountTooSmall: Bool {
    guard let from = from, let to = to else {
      return false
    }
    if self.fromAmount <= BigInt(0) { return true }
    if from.isETH || from.isWETH || from.isBNB {
      return self.fromAmount < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    if to.isETH || to.isWETH {
      return self.toAmount < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    return false
  }

  var isBalanceEnough: Bool {
    guard let from = from else {
      return true
    }
    if self.fromAmount > from.getBalanceBigInt() { return false }
    return true
  }

  var isAmountTooBig: Bool {
    if !self.isBalanceEnough { return true }
    return false
  }

  var isAmountValid: Bool {
    return !self.isAmountTooSmall && !self.isAmountTooBig
  }

  // rate should not be nil and greater than zero
  var isSlippageRateValid: Bool {
    if self.slippageRate == nil || self.slippageRate?.isZero == true { return false }
    return true
  }

  var isRateValid: Bool {
    if self.estRate == nil || self.estRate?.isZero == true { return false }
    if self.slippageRate == nil || self.slippageRate?.isZero == true { return false }
    return true
  }

  var feeBigInt: BigInt {
    return self.gasPrice * self.estimateGasLimit
  }

  var minDestQty: BigInt {
    return self.toAmount * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var maxAmtSold: BigInt {
    return self.fromAmount * BigInt(10000.0 + self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var displayMinDestAmount: String? {
    guard let to = to else { return nil }
    return self.minDestQty.string(decimals: to.decimals, minFractionDigits: min(to.decimals, 5), maxFractionDigits: min(to.decimals, 5)) + " " + to.symbol
  }

  var displayMaxSoldAmount: String? {
    guard let from = from else { return nil }
    return self.maxAmtSold.string(decimals: from.decimals, minFractionDigits: min(from.decimals, 5), maxFractionDigits: min(from.decimals, 5)) + " " + from.symbol
  }

  var displayExpectedReceiveValue: String? {
    return self.isFocusingFromAmount ? self.displayMinDestAmount : self.displayMaxSoldAmount
  }

  var displayExpectedReceiveTitle: String {
    return self.isFocusingFromAmount ? "Minimum received" : "Maximum sold"
  }

  var isHavingEnoughETHForFee: Bool {
    var fee = self.gasPrice * self.estimateGasLimit
    guard let from = from else {
      return true
    }
    if from.isETH || from.isBNB { fee += self.fromAmount }
    let quoteBalance = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return quoteBalance >= fee
  }

  var amountFromStringParameter: String {
    var param = self.amountFrom.removeGroupSeparator()
    let decimals: Character = EtherNumberFormatter.short.decimalSeparator.first!
    if String(decimals) != "." {
      param = param.replacingOccurrences(of: String(decimals), with: ".")
    }
    return param
  }

  var gasFeeString: NSAttributedString {
    let sourceToken = KNGeneralProvider.shared.quoteToken
    let fee = self.gasPrice * self.estimateGasLimit
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
      typeString = "advanced".uppercased()
    }
    
    let gasPriceAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!,
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 14),
      NSAttributedString.Key.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!,
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 14),
      NSAttributedString.Key.kern: 0.0,
    ]
    
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(feeString) \(sourceToken) ", attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: "(\(typeString))", attributes: feeAttributes))
    return attributedString
  }

  var slippageString: String {
    let doubleStr = String(format: "%.2f", self.minRatePercent)
    return "\(doubleStr)%"
  }

  func resetDefaultTokensPair() {
    if self.isFromDeepLink {
      return
    }
    self.from = KNGeneralProvider.shared.currentChain.quoteTokenObject()
    self.to = nil
  }

  func updateTokensPair(from: TokenObject, to: TokenObject) {
    self.from = from
    self.to = to
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.addressString
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    self.resetDefaultTokensPair()

    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true
    self.isSwapAllBalance = false

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = defaultGasLimit
    self.baseGasLimit = defaultGasLimit
  }

  func updateWalletObject() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address)?.clone() ?? self.walletObject
  }

  func swapTokens() {
    swap(&self.from, &self.to)
    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true
    self.isSwapAllBalance = false

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = defaultGasLimit
    self.baseGasLimit = defaultGasLimit
  }

  func updateSelectedToken(_ token: TokenObject, isSource: Bool) {
    if isSource {
      self.from = token.clone()
    } else {
      self.to = token.clone()
    }
    if self.isFocusingFromAmount && isSource {
      // focusing on from amount, and from token is changed, reset amount
      self.amountFrom = ""
      self.isSwapAllBalance = false
    } else if !self.isFocusingFromAmount && !isSource {
      // focusing on to amount, and to token is changed, reset to amount
      self.amountTo = ""
    }
    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = defaultGasLimit
    self.baseGasLimit = defaultGasLimit
  }

  func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }

  func updateAmount(_ amount: String, isSource: Bool, forSwapAllETH: Bool = false) {
    if isSource {
      self.amountFrom = amount
      guard !forSwapAllETH else { return }
      self.isSwapAllBalance = false
    } else {
      self.amountTo = amount
    }
  }

  func updateBalance(_ balances: [String: Balance]) {
  }

  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
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
        self.estimateGasLimit = customGasLimit
      }
    default: break
    }
  }

  // update when set gas price
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
  }

  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  func updateEstimateGasLimit(for from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.to, !self.isAmountFromChanged(newAmount: amount, oldAmount: self.fromAmount) {
      if let customGasLimitString = self.advancedGasLimit, let customGasLimit = BigInt(customGasLimitString), customGasLimit > gasLimit {
        self.baseGasLimit = gasLimit
      } else {
        self.estimateGasLimit = gasLimit
        self.baseGasLimit = gasLimit
      }
    }
  }

  var defaultGasLimit: BigInt {
    guard let from = from, let to = to else { return BigInt(0) }
    return KNGasConfiguration.calculateDefaultGasLimit(from: from, to: to)
  }

  // if different less than 3%, consider as no changes
  private func isAmountFromChanged(newAmount: BigInt, oldAmount: BigInt) -> Bool {
    guard let from = from else { return false }
    if oldAmount == newAmount { return false }
    let different = abs(oldAmount - newAmount)
    if different <= oldAmount * BigInt(3) / BigInt(100) { return false }
    let doubleValue = Double(newAmount) / pow(10.0, Double(from.decimals))
    return !(oldAmount.isZero && doubleValue == 0.001)
  }

  func getHint(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged = isAmountChanged(amount: amount)
    
    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return ""
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      return platform == element.platform
    }
    return rateDict?.hint ?? ""
  }

  func getSwapRate(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged = isAmountChanged(amount: amount)

    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return ""
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      return platform == element.platform
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

  func updateSwapRates(from: TokenObject, to: TokenObject, amount: BigInt, rates: [Rate]) {
    guard from.isEqual(self.from), to.isEqual(self.to) else {
      return
    }
    self.swapRates = (from.address.lowercased(), to.address.lowercased(), amount, rates)

    self.swapRates.3.forEach { (element) in
      if element.platform == self.currentFlatform {
        element.estimatedGas = Int(self.estimateGasLimit)
      }
    }
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
      if let platformString = dict?.platform {
        self.currentFlatform = platformString
      }
    } else {
      //MAX RETUN = max rate
      let max = rates.max { (left, right) -> Bool in
        if let leftBigInt = BigInt(left.rate), let rightBigInt = BigInt(right.rate) {
          return leftBigInt < rightBigInt
        } else {
          return false
        }
      }
      if let platformString = max?.platform {
        self.currentFlatform = platformString
      }
    }
  }

  func updateRefPrice(from: TokenObject, to: TokenObject, change: String, source: [String]) {
    guard from.isEqual(self.from), to.isEqual(self.to) else {
      return
    }
    self.refPrice = (from, to, change, source)
  }

  func getRefPrice(from: TokenObject, to: TokenObject) -> String {
    guard let refPrice = refPrice, from.isEqual(refPrice.from), from.isEqual(refPrice.to) else {
      return ""
    }
    return refPrice.price
  }
  
  var refPriceSource: String {
    guard let refPrice = refPrice, !refPrice.sources.isEmpty else {
      return ""
    }
    return "Reference.price.is.from".toBeLocalised() + refPrice.sources.joined(separator: ", ") + "."
  }

  var refPriceDiffText: String {
    guard let from = from, let to = to else {
      return "---"
    }
    guard !self.getRefPrice(from: from, to: to).isEmpty else {
      return "---"
    }
    return StringFormatter.percentString(value: self.priceImpactValue / 100)
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

  var priceImpactValue: Double {
    guard let from = from, let to = to else {
      return 0
    }
    guard !self.amountFrom.isEmpty else {
      return 0
    }
    let refPrice = self.getRefPrice(from: from, to: to)
    let price = self.getSwapRate(from: from.address, to: to.address, amount: self.fromAmount, platform: self.currentFlatform)

    guard !price.isEmpty, !refPrice.isEmpty, let priceBigInt = BigInt(price) else {
      return 0
    }
    let refPriceDouble = refPrice.doubleValue
    let priceDouble: Double = Double(priceBigInt) / pow(10.0, 18)
    let change = (priceDouble - refPriceDouble) / refPriceDouble * 100.0
    return change
  }

  @discardableResult
  func updateExpectedRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt) -> Bool {
    let isAmountChanged = isAmountChanged(amount: amount)
    if from == self.from, to == self.to, !isAmountChanged {
      self.estRate = rate
      return true
    }
    return false
  }

  func buildRawSwapTx() -> RawSwapTransaction? {
    guard let from = from, let to = to else { return nil }
    return RawSwapTransaction(
      userAddress: self.wallet.addressString,
      src: from.address ,
      dest: to.address,
      srcQty: self.fromAmount.description,
      minDesQty: self.minDestQty.description,
      gasPrice: self.gasPrice.description,
      nonce: self.latestNonce,
      hint: self.getHint(
        from: from.address,
        to: to.address,
        amount: self.fromAmount,
        platform: self.currentFlatform
      ),
      useGasToken: self.isUseGasToken
    )
  }

  func buildSignSwapTx(_ object: TxObject) -> SignTransaction? {
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
    
    if case let .real(account) = self.wallet.type {
      return SignTransaction(
        value: value,
        account: account,
        to: Address(string: object.to),
        nonce: nonce,
        data: Data(hex: object.data.drop0x),
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        chainID: KNGeneralProvider.shared.customRPC.chainID
      )
    } else {
      //TODO: handle watch wallet type
      return nil
    }
  }
  
  func buildEIP1559Tx(_ object: TxObject) -> EIP1559Transaction? {
    guard let baseFeeBigInt = KNGasCoordinator.shared.baseFee else { return nil }
    let gasLimitDefault = BigInt(object.gasLimit.drop0x, radix: 16) ?? self.estimateGasLimit
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

  func resetAdvancedSettings() {
    self.advancedGasLimit = nil
    self.advancedMaxPriorityFee = nil
    self.advancedMaxFee = nil
    self.advancedNonce = nil
    if self.selectedGasPriceType == .custom {
      self.selectedGasPriceType = .medium
    }
  }

  var isUseEIP1559: Bool {
    return KNGeneralProvider.shared.isUseEIP1559
  }
  
  var displayEstGas: String {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return ""
    }
    let baseFee = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let fee = (baseFee + self.selectedPriorityFee) * self.baseGasLimit
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
  
  var shouldShowCommingSoon: Bool {
    return KNGeneralProvider.shared.currentChain == .solana
  }
}

extension KSwapViewModel {
  func getChain(chainId: Int) -> ChainType? {
    return ChainType.make(chainID: chainId)
  }

  func chainName(chainId: Int) -> String? {
    return ChainType.make(chainID: chainId)?.chainName()
  }
}


extension KSwapViewModel {
  
  private func isAmountChanged(amount: BigInt) -> Bool {
    guard let from = from else { return false }
    if self.fromAmount == amount { return false }
    let doubleValue = Double(amount) / pow(10.0, Double(from.decimals))
    return !(self.fromAmount.isZero && doubleValue == 0.001)
  }
  
}

extension KSwapViewModel {
  
  typealias SwapValidationError = (title: String, message: String)
  
  // FIXME: localize message
  func validate(isConfirming: Bool) -> ValidationResult<SwapValidationError> {
    guard let from = from else {
      return isConfirming ?
        .failure(error: (title: Strings.invalidInput, message: Strings.pleaseSelectSourceToken))
      : .success
    }
    guard let to = to else {
      return isConfirming ?
        .failure(error: (title: Strings.invalidInput, message: Strings.pleaseSelectDestToken)) :
        .success
    }
    
    let estRate = getSwapRate(from: from.address.lowercased(),
                              to: to.address.lowercased(),
                              amount: fromAmount,
                              platform: currentFlatform).bigInt
    
    if from == to {
      return .failure(error: (title: Strings.unsupported,
                              message: Strings.canNotSwapSameToken))
    }
    
    if amountFrom.isEmpty {
      return .failure(error: (title: Strings.invalidInput,
                              message: Strings.pleaseEnterAmountToContinue))
    }
    
    if estRate?.isZero ?? true {
      return .failure(error: (title: "",
                              message: Strings.canNotFindExchangeRate))
    }
    
    if !isBalanceEnough {
      return .failure(error: (title: Strings.amountTooBig,
                              message: Strings.balanceNotEnoughToMakeTransaction))
    }
    
    if isAmountTooSmall {
      return .failure(error: (title: Strings.invalidAmount,
                              message: Strings.amountTooSmallToSwap))
    }
    
    if isConfirming {
      let quoteToken = KNGeneralProvider.shared.quoteToken
      
      if !isHavingEnoughETHForFee {
        let title = String(format: Strings.insufficientXForTransaction, quoteToken)
        let message = String(format: Strings.depositMoreXOrClickAdvancedToLowerGasFee, feeBigInt.shortString(units: .ether, maxFractionDigits: 5))
        return .failure(error: (title: title, message: message))
      }
      
      if estRate?.isZero ?? true {
        return .failure(error: (title: Strings.rateMightChange, message: Strings.pleaseWaitForExpectedRateUpdate))
      }
    }
   
    return .success
  }
  
}
