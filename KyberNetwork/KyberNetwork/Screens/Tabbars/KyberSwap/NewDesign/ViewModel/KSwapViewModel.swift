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

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: TokenObject

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var estRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?
  fileprivate(set) var minRatePercent: Double = 1.0

  var isSwapAllBalance: Bool = false
  var isTappedSwapAllBalance: Bool = false

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas

  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault
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
  var refPrice: (TokenObject, TokenObject, String, [String])
  var gasPriceSelectedAmount: (String, String) = ("", "")
  var approvingToken: TokenObject?
  var showingRevertRate: Bool = false
  
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
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr)?.clone() ?? KNWalletObject(address: addr)
    self.from = from.clone()
    self.to = to.clone()
    self.supportedTokens = supportedTokens.map({ return $0.clone() })
    self.refPrice = (self.from, self.to, "", [])
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

  var allFromTokenBalanceString: String {
    if self.from.isQuoteToken {
      let balance = self.from.getBalanceBigInt()
      if balance <= self.feeBigInt { return "0" }
      let fee = self.allETHBalanceFee
      let availableToSwap = max(BigInt(0), balance - fee)
      let string = availableToSwap.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 5)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.balanceText.removeGroupSeparator()
  }

  var amountFromBigInt: BigInt {
    return self.amountFrom.removeGroupSeparator().amountBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var amountToEstimate: BigInt {
    if self.amountFromBigInt.isZero, let smallAmount = EtherNumberFormatter.short.number(from: "0.001", decimals: self.from.decimals) {
      return smallAmount
    }
    return self.amountFromBigInt
  }

  var equivalentUSDAmount: BigInt? {
    if let usdRate = KNTrackerRateStorage.shared.getPriceWithAddress(self.from.address) {
      return self.amountFromBigInt * BigInt(usdRate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.from.decimals)
    }
    return nil
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var fromTokenIconName: String {
    return self.from.icon
  }

  var isFromTokenBtnEnabled: Bool {
    guard KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) != nil else {
      // not a promo wallet, always enabled
      return true
    }
    if self.from.isPromoToken { return false }
    return true
  }

  var fromTokenBtnTitle: String {
    return self.from.symbol
  }

  // when user wants to fix received amount
  var expectedExchangeAmountText: String { //TODO: Improve loading rate later
    guard !self.amountToBigInt.isZero else {
      return ""
    }
    let rate = self.getCurrentRate() ?? BigInt(0)
    let expectedExchange: BigInt = {
      if rate.isZero { return BigInt(0) }
      let amount = self.amountToBigInt * BigInt(10).power(18) * BigInt(10).power(self.from.decimals)
      return amount / rate / BigInt(10).power(self.to.decimals)
    }()
    return expectedExchange.string(
      decimals: self.from.decimals,
      minFractionDigits: self.from.decimals,
      maxFractionDigits: self.from.decimals
    ).removeGroupSeparator()
  }

  // MARK: To Token
  var amountToBigInt: BigInt {
    return self.amountTo.removeGroupSeparator().amountBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var isToTokenBtnEnabled: Bool {
    guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) else {
      // not a promo wallet, always enabled
      return true
    }
    if self.from.isPromoToken && self.to.symbol == destToken { return false }
    return true
  }

  var toTokenBtnTitle: String {
    return self.to.symbol
  }

  var toTokenIconName: String {
    return self.to.icon
  }

  var amountTextFieldColor: UIColor {
    return self.isAmountValid ? UIColor.Kyber.enygold : UIColor.red
  }

  var expectedReceivedAmountText: String {
    guard !self.amountFromBigInt.isZero else {
      return ""
    }

    let expectedRate = self.getCurrentRate() ?? BigInt(0)
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return expectedRate * amount * BigInt(10).power(self.to.decimals) / BigInt(10).power(18) / BigInt(10).power(self.from.decimals)
    }()
    return expectedAmount.string(
      decimals: self.to.decimals,
      minFractionDigits: min(self.to.decimals, 5),
      maxFractionDigits: min(self.to.decimals, 5)
    ).removeGroupSeparator()
  }

  func tokenButtonText(isSource: Bool) -> String {
    return isSource ? self.from.symbol : self.to.symbol
  }

  // MARK: Balance
  var balanceText: String {
    let bal: BigInt = self.from.getBalanceBigInt()
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 5)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }
  
  var balanceDisplayText: String {
    return "\(self.balanceText) \(self.from.symbol)"
  }

  var balanceTextString: String {
    let balanceText = NSLocalizedString("balance", value: "Balance", comment: "")
    return "\(self.from.symbol) \(balanceText)".uppercased()
  }

  // MARK: Rate
  var exchangeRateText: String {
    if self.showingRevertRate {
      return self.displayRevertRate
    } else {
      return displayExchangeRate
    }
  }

  var displayExchangeRate: String {
    let rateString: String = self.getSwapRate(from: self.from.address.lowercased(), to: self.to.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    let rate = BigInt(rateString)
    if let notNilRate = rate {
      return notNilRate.isZero ? "---" : "Rate: 1 \(self.from.symbol) = \(notNilRate.displayRate(decimals: 18)) \(self.to.symbol)"
    } else {
      return "---"
    }
  }

  var displayRevertRate: String {
    let rateString: String = self.getSwapRate(from: self.from.address.lowercased(), to: self.to.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    let rate = BigInt(rateString)
    if let notNilRate = rate, notNilRate != BigInt(0) {
      let revertRate = BigInt(10).power(36) / notNilRate
      return notNilRate.isZero ? "---" : "Rate: 1 \(self.to.symbol) = \(revertRate.displayRate(decimals: 18)) \(self.from.symbol)"
    } else {
      return "---"
    }
  }

  func getCurrentRate() -> BigInt? {
    let rateString: String = self.getSwapRate(from: self.from.address.lowercased(), to: self.to.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    return BigInt(rateString)
  }

  var minRate: BigInt? {
    guard let estRate = self.estRate else { return nil }
    return estRate * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var slippageRateText: String? {
    return self.slippageRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: min(self.to.decimals, 9))
  }

  // MARK: Gas Price
  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountTooSmall: Bool {
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.isETH || self.from.isWETH || self.from.isBNB {
      return self.amountFromBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    if self.to.isETH || self.to.isWETH {
      return self.amountToBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    return false
  }

  var isBalanceEnough: Bool {
    if self.amountFromBigInt > self.from.getBalanceBigInt() { return false }
    return true
  }

  var isAmountTooBig: Bool {
    if !self.isBalanceEnough { return true }
    return false
  }

  var isETHSwapAmountAndFeeTooBig: Bool {
    if !self.from.isETH || self.from.isBNB { return false } // not ETH
    let totalValue = self.feeBigInt + self.amountFromBigInt
    let balance = self.from.getBalanceBigInt()
    return balance < totalValue
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
    return self.amountToBigInt * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var maxAmtSold: BigInt {
    return self.amountFromBigInt * BigInt(10000.0 + self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var displayMinDestAmount: String {
    return self.minDestQty.string(decimals: self.to.decimals, minFractionDigits: 4, maxFractionDigits: 4) + " " + self.to.symbol
  }

  var displayMaxSoldAmount: String {
    return self.maxAmtSold.string(decimals: self.from.decimals, minFractionDigits: 4, maxFractionDigits: 4) + " " + self.from.symbol
  }

  var displayExpectedReceiveValue: String {
    return self.isFocusingFromAmount ? self.displayMinDestAmount : self.displayMaxSoldAmount
  }

  var displayExpectedReceiveTitle: String {
    return self.isFocusingFromAmount ? "Minimum received" : "Maximum sold"
  }

  var isHavingEnoughETHForFee: Bool {
    var fee = self.gasPrice * self.estimateGasLimit
    if self.from.isETH || self.from.isBNB { fee += self.amountFromBigInt }
    let ethBal = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return ethBal >= fee
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
    switch KNGeneralProvider.shared.currentChain {
    case .eth:
      self.from = KNSupportedTokenStorage.shared.ethToken
      self.to = KNSupportedTokenStorage.shared.kncToken
    case .bsc:
      self.from = KNSupportedTokenStorage.shared.bnbToken
      self.to = KNSupportedTokenStorage.shared.busdToken
    case .polygon:
      self.from = KNSupportedTokenStorage.shared.maticToken
      self.to = KNSupportedTokenStorage.shared.usdcToken
    case .avalanche:
      self.from = KNSupportedTokenStorage.shared.avaxToken
      self.to = KNSupportedTokenStorage.shared.usdceToken
    }
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    self.resetDefaultTokensPair()

    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true
    self.isSwapAllBalance = false

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = self.getDefaultGasLimit(for: self.from, to: self.to)
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
    self.estimateGasLimit = self.getDefaultGasLimit(for: self.from, to: self.to)
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
    self.estimateGasLimit = self.getDefaultGasLimit(for: self.from, to: self.to)
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

  @discardableResult
  func updateExchangeRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) -> Bool {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    if from == self.from, to == self.to, !isAmountChanged {
      self.estRate = rate
      self.slippageRate = slippageRate
      return true
    }
    return false
  }

  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  func updateEstimateGasLimit(for from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.to, !self.isAmountFromChanged(newAmount: amount, oldAmount: self.amountFromBigInt) {
      if let customGasLimitString = self.advancedGasLimit, let customGasLimit = BigInt(customGasLimitString), customGasLimit > gasLimit {
        return
      } else {
        self.estimateGasLimit = gasLimit
        self.resetAdvancedSettings()
      }
    }
    self.swapRates.3.forEach { (element) in
      if element.platform == self.currentFlatform {
        element.estimatedGas = Int(gasLimit)
      }
    }
  }

  func getDefaultGasLimit(for from: TokenObject, to: TokenObject) -> BigInt {
    return KNGasConfiguration.calculateDefaultGasLimit(from: from, to: to)
  }

  // if different less than 3%, consider as no changes
  private func isAmountFromChanged(newAmount: BigInt, oldAmount: BigInt) -> Bool {
    if oldAmount == newAmount { return false }
    let different = abs(oldAmount - newAmount)
    if different <= oldAmount * BigInt(3) / BigInt(100) { return false }
    let doubleValue = Double(newAmount) / pow(10.0, Double(self.from.decimals))
    return !(oldAmount.isZero && doubleValue == 0.001)
  }

  func getHint(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return ""
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      return platform == element.platform
    }
    if let rateString = rateDict?.hint {
      return rateString
    } else {
      return ""
    }
  }

  func getSwapRate(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()

    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return ""
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      return platform == element.platform
    }
    if let rateString = rateDict?.rate {
      return rateString
    } else {
      return ""
    }
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
      //MAX RETUN = destAmount * price - gasFee
      let max = rates.max { (left, right) -> Bool in
        if let leftBigInt = BigInt(left.rate), let rightBigInt = BigInt(right.rate) {
          let leftValue = self.amountToBigInt * leftBigInt - self.gasPrice * BigInt(left.estimatedGas)
          let rightValue = self.amountToBigInt * rightBigInt - self.gasPrice * BigInt(right.estimatedGas)
          return leftValue < rightValue
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
    guard from.isEqual(self.refPrice.0), to.isEqual(self.refPrice.1) else {
      return ""
    }
    return self.refPrice.2
  }

  var refPriceDiffText: String {
    guard !self.amountFrom.isEmpty else {
      return "---"
    }
    let refPrice = self.getRefPrice(from: self.from, to: self.to)
    let price = self.getSwapRate(from: self.from.address.description, to: self.to.address.description, amount: self.amountFromBigInt, platform: self.currentFlatform)
    guard !price.isEmpty, !refPrice.isEmpty, let priceBigInt = BigInt(price) else {
      return ""
    }
    let refPriceDouble = refPrice.doubleValue
    let priceDouble: Double = Double(priceBigInt) / pow(10.0, 18)
    let change = (priceDouble - refPriceDouble) / refPriceDouble * 100.0
    if change > -5.0 {
      return "---"
    } else {
      let displayPercent = "\(change)".prefix(6)
      return "↓ \(displayPercent)%"
    }
  }

  @discardableResult
  func updateExpectedRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt) -> Bool {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    if from == self.from, to == self.to, !isAmountChanged {
      self.estRate = rate
      return true
    }
    return false
  }

  func buildRawSwapTx() -> RawSwapTransaction {
    return RawSwapTransaction(
      userAddress: self.wallet.address.description,
      src: self.from.address ,
      dest: self.to.address,
      srcQty: self.amountFromBigInt.description,
      minDesQty: self.minDestQty.description,
      gasPrice: self.gasPrice.description,
      nonce: self.latestNonce,
      hint: self.getHint(
        from: self.from.address,
        to: self.to.address,
        amount: self.amountFromBigInt,
        platform: self.currentFlatform
      ),
      useGasToken: self.isUseGasToken
    )
  }

  func buildSignSwapTx(_ object: TxObject) -> SignTransaction? {
    guard
      let value = BigInt(object.value.drop0x, radix: 16),
      let gasPrice = BigInt(object.gasPrice.drop0x, radix: 16),
      let gasLimit = BigInt(object.gasLimit.drop0x, radix: 16),
      let nonce = Int(object.nonce.drop0x, radix: 16)
    else
    {
      return nil
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
    let priorityFeeBigIntDefault = gasPrice - baseFeeBigInt
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
       let priorityFee = BigInt(priorityFeeString),
       let maxGasFeeString = self.advancedMaxFee,
       let maxGasFee = BigInt(maxGasFeeString) {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFee.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
        toAddress: object.to,
        fromAddress: object.from,
        data: object.data,
        value: object.value.drop0x.hexSigned2Complement
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
        value: object.value.drop0x.hexSigned2Complement
      )
    }
  }

  func resetAdvancedSettings() {
    self.advancedGasLimit = nil
    self.advancedMaxPriorityFee = nil
    self.advancedMaxFee = nil
    if self.selectedGasPriceType == .custom {
      self.selectedGasPriceType = .medium
    }
  }

  var isUseEIP1559: Bool {
    return KNGeneralProvider.shared.currentChain == .eth //TODO: determine more detail later
  }
}
