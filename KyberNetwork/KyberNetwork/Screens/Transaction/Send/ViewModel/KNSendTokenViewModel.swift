// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import KrystalWallets
import Services
import AppState
import TransactionModule
import BaseModule

class KNSendTokenViewModel: BaseViewModel {

  fileprivate let gasPrices: [BigInt] = [
    KNGasConfiguration.gasPriceMin,
    KNGasConfiguration.gasPriceDefault,
    KNGasConfiguration.gasPriceMax,
  ]

  let defaultTokenIconImg = UIImage(named: "default_token")

  fileprivate(set) var from: TokenObject

  fileprivate(set) var amount: String = ""
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault
  fileprivate(set) var baseGasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault
  
  ///solana default lamport per signature
  fileprivate(set) var lamportPerSignature: BigInt = SolFeeCoordinator.shared.lamportPerSignature
  fileprivate(set) var minimumRentExemption: BigInt = SolFeeCoordinator.shared.minimumRentExemption
  fileprivate(set) var totalSignature: BigInt = BigInt(1)
  
  private(set) var inputAddress: String = ""
  private(set) var address: String?
  private(set) var isUsingEns: Bool = false
  var onGetBalanceFromNodeCompleted: (() -> Void)?

  var isSendAllBalanace: Bool = false
    
  var sourceBalance: BigInt = BigInt(0) {
    didSet {
        onGetBalanceFromNodeCompleted?()
    }
  }

  var addressName: String {
    return currentAddress.name
  }
  
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

  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }
    
  var l1Fee: BigInt = BigInt(0)

  var allTokenBalanceString: String {
    if self.from.isQuoteToken {
      var availableValue = BigInt(0)
      if KNGeneralProvider.shared.currentChain == .solana {
        availableValue = max(BigInt(0), sourceBalance - self.solanaFeeBigInt)
      } else {
        availableValue = max(BigInt(0), sourceBalance - self.allETHBalanceFee)
      }
      let string = availableValue.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 5)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.displayBalance.removeGroupSeparator()
  }

  var amountBigInt: BigInt {
    return amount.amountBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var equivalentUSDAmount: BigInt? {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.from.address) else { return nil }
    
    return self.amountBigInt * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(self.from.decimals)
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var amountTextColor: UIColor {
    return isAmountValid ? UIColor.white : UIColor.red
  }

  var currentWalletAddress: String {
    return currentAddress.addressString
  }

  init(from: TokenObject, balances: [String: Balance], currentAddress: String, recipientAddress: String = "") {
    self.from = from.clone()
    self.isSendAllBalanace = false
    self.gasLimit = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: from)
    self.baseGasLimit = self.gasLimit
    super.init()
    self.updateInputString(recipientAddress)
  }

  var navTitle: String {
    return Strings.transfer
  }

  var tokenButtonAttributedText: NSAttributedString {
    // only have symbol and logo
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.medium(with: 22),
      NSAttributedString.Key.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
      NSAttributedString.Key.kern: 0.0,
    ]
    attributedString.append(NSAttributedString(string: "\(self.from.symbol.prefix(8))", attributes: symbolAttributes))
    return attributedString
  }

  var tokenButtonText: String {
    return String(self.from.symbol.prefix(8))
  }
  
  func resetFromToken() {
    self.from = KNGeneralProvider.shared.quoteTokenObject
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let sourceToken = KNGeneralProvider.shared.quoteToken
    let fee = gasPrice * self.gasLimit + self.l1Fee
    let feeString: String = NumberFormatUtils.gasFeeFormat(number: fee)
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
    return "\(feeString) \(sourceToken) (\(typeString))"
  }
  
  fileprivate func formatSolFeeStringFor(fee: BigInt) -> String {
    let feeString: String = fee.string(decimals: 9, minFractionDigits: 0, maxFractionDigits: 9)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  var gasFeeString: String {
    self.updateSelectedGasPriceType(self.selectedGasPriceType)
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }
  
  var solFeeString: String {
    return self.formatSolFeeStringFor(fee: self.solanaFeeBigInt)
  }
  
  var solFeeWithRentTokenAccountFeeString: String {
    return self.formatSolFeeStringFor(fee: self.solanaFeeBigInt + self.minimumRentExemption)
  }

  var balanceText: String {
    let balanceText = NSLocalizedString("balance", value: "Balance", comment: "")
    return "\(self.from.symbol.prefix(8)) \(balanceText)".uppercased()
  }

  var displayBalance: String {
    return NumberFormatUtils.balanceFormat(value: self.sourceBalance, decimals: self.from.decimals)
  }

  var totalBalanceText: String {
    if KNGeneralProvider.shared.isBrowsingMode {
      return "0 \(self.from.symbol)"
    }
    return "\(self.displayBalance) \(self.from.symbol)"
  }

  var placeHolderEnterAddress: NSAttributedString {
    let attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedString.Key.foregroundColor: UIColor(red: 66, green: 87, blue: 95),
    ]
    let placeHolderString = KNGeneralProvider.shared.currentChain == .eth ? "Recipient Address/ENS".toBeLocalised() : "Recipient Address".toBeLocalised()
    return NSAttributedString(string: placeHolderString, attributes: attributes)
  }

  var placeHolderAmount: NSAttributedString {
    let attributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedString.Key.foregroundColor: UIColor(red: 66, green: 87, blue: 95),
    ]
    return NSAttributedString(string: "0", attributes: attributes)
  }

  var displayAddress: String? {
    if self.address == nil { return self.inputAddress }
    if let contact = KNContactStorage.shared.contacts.first(where: { self.inputAddress == $0.address}) {
      return "\(contact.name) - \(self.inputAddress)"
    }
    return self.inputAddress
  }

  var displayEnsMessage: String? {
    if self.inputAddress.isEmpty { return nil }
    guard let address = self.address else {
      return "Invalid address or your ens is not mapped yet"
    }
    if KNGeneralProvider.shared.isAddressValid(address: self.inputAddress) { return nil }
    return "\(address.prefix(12))...\(address.suffix(10))"
  }

  var displayEnsMessageColor: UIColor {
    if self.address == nil { return UIColor.Kyber.strawberry }
    return UIColor.Kyber.blueGreen
  }

  var newContactTitle: String {
    let addr = self.address?.description.lowercased() ?? ""
    if KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == addr }) != nil {
      return NSLocalizedString("edit.contact", comment: "")
    }
    return NSLocalizedString("add.contact", comment: "")
  }

  var isAmountTooSmall: Bool {
    if self.from.isETH || self.from.isBNB { return false }
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    return amountBigInt > sourceBalance
  }

  var isAmountValid: Bool {
    return !isAmountTooBig && !isAmountTooSmall
  }

  var isAddressValid: Bool {
    return self.address != nil && KNGeneralProvider.shared.isAddressValid(address: self.address!)
  }

  var ethFeeBigInt: BigInt {
    return self.gasPrice * self.gasLimit
  }
  
  var solanaFeeBigInt: BigInt {
    return self.lamportPerSignature * self.totalSignature
  }

  var isHavingEnoughETHForFee: Bool {
    var fee = self.ethFeeBigInt
    if self.from.isETH || self.from.isBNB { fee += self.amountBigInt }
    let ethBal = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return ethBal >= fee
  }
  
  var isHavingEnoughSolForFee: Bool {
    let solBalance = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return solBalance > self.solanaFeeBigInt
  }

  var unconfirmTransaction: UnconfirmedTransaction {
    let transferType: TransferType = {
      if self.from.isQuoteToken {
        return TransferType.ether(destination: self.address)
      }
      return TransferType.token(self.from)
    }()
    let amount: BigInt = {
      if self.from.isQuoteToken {
        // eth needs to minus some fee
        if !self.isSendAllBalanace { return self.amountBigInt } // not send all balance
        return max(BigInt(0), sourceBalance - self.allETHBalanceFee)
      }
      return self.isSendAllBalanace ? self.sourceBalance : self.amountBigInt
    }()

    if KNGeneralProvider.shared.isUseEIP1559 {
      var nonce: BigInt?
      if let customNonce = self.advancedNonce, let customNonceInt = Int(customNonce) {
        let customNonceBigInt = BigInt(customNonceInt)
        nonce = customNonceBigInt
      }
      if let advancedGasStr = self.advancedGasLimit,
         let gasLimit = BigInt(advancedGasStr),
         let priorityFeeString = self.advancedMaxPriorityFee,
         let maxGasFeeString = self.advancedMaxFee {
        return UnconfirmedTransaction(
          transferType: transferType,
          value: amount,
          to: self.address ?? "",
          data: nil,
          gasLimit: gasLimit,
          gasPrice: self.gasPrice,
          nonce: nonce,
          maxInclusionFeePerGas: priorityFeeString,
          maxGasFee: maxGasFeeString
        )
      } else {
//        let baseFeeBigInt = KNGasCoordinator.shared.baseFee ?? BigInt(0)
        let priorityFeeBigIntDefault = self.selectedPriorityFee
        return UnconfirmedTransaction(
          transferType: transferType,
          value: amount,
          to: self.address ?? "",
          data: nil,
          gasLimit: self.gasLimit,
          gasPrice: self.gasPrice,
          nonce: nonce,
          maxInclusionFeePerGas: priorityFeeBigIntDefault.shortString(units: UnitConfiguration.gasPriceUnit),
          maxGasFee: self.gasPrice.shortString(units: UnitConfiguration.gasPriceUnit)
        )
      }
    } else {
      var txGasPrice = self.gasPrice
      var txGasLimit = self.gasLimit
      var txNonce: BigInt? = .none
      if let unwrap = self.advancedMaxFee, let value = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
        txGasPrice = value
      }
      
      if let unwrap = self.advancedGasLimit, let value = BigInt(unwrap) {
        txGasLimit = value
      }
      
      if let unwrap = self.advancedNonce, let value = Int(unwrap) {
        txNonce = BigInt(value)
      }
      return UnconfirmedTransaction(
        transferType: transferType,
        value: amount,
        to: self.address ?? "",
        data: nil,
        gasLimit: txGasLimit,
        gasPrice: txGasPrice,
        nonce: txNonce,
        maxInclusionFeePerGas: nil,
        maxGasFee: nil
      )
    }
  }
  
//  var solanaUnconfirmTransaction: UnconfirmedTransaction {
//
//  }

  var isNeedUpdateEstFeeForTransferingAllBalance: Bool = false

  // MARK: Update
  func updateSendToken(from token: TokenObject, balance: Balance?) {
    self.from = token.clone()
    self.amount = ""
    self.isSendAllBalanace = false
    self.gasLimit = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: self.from)
    self.baseGasLimit = self.gasLimit
    self.getNodeBalance()
  }

    func getNodeBalance() {
        EthereumNodeService(chain: AppState.shared.currentChain).getBalance(address: currentAddress.addressString, tokenAddress: self.from.address) { [weak self] balance in
            self?.sourceBalance = balance
        }
    }

  func updateAmount(_ amount: String, forSendAllETH: Bool = false) {
    self.amount = amount
    guard !forSendAllETH else {
      return
    }
    self.isSendAllBalanace = false
  }

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
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
        self.gasLimit = customGasLimit
      }
    default: return
    }
  }

  @discardableResult
  func updateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, address: String) -> Bool {
    if self.from == from, self.inputAddress == address {
      if self.selectedGasPriceType == .custom {
        self.baseGasLimit = gasLimit
      } else {
        self.gasLimit = gasLimit
        self.baseGasLimit = gasLimit
      }
      
      return true
    }
    return false
  }

  func updateInputString(_ address: String) {
    self.inputAddress = address
    if KNGeneralProvider.shared.isAddressValid(address: address) {
      self.isUsingEns = false
      self.address = inputAddress
    }
  }

  func updateAddressFromENS(_ ens: String, ensAddr: String?) {
    if ens == self.inputAddress {
      self.address = ensAddr
      self.isUsingEns = KNGeneralProvider.shared.isAddressValid(address: ensAddr ?? "")
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
  
  var displayEstGas: String {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return ""
    }
    let baseFee = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let fee = (baseFee + self.selectedPriorityFee + self.l1Fee) * self.gasLimit
    let sourceToken = KNGeneralProvider.shared.quoteToken
    let feeString: String = NumberFormatUtils.gasFeeFormat(number: fee)
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
}
