//
//  GasFeeSelectorPopupViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 10/01/2022.
//
import BigInt
import KrystalWallets

enum KNSelectedGasPriceType: Int {
  case fast = 0
  case medium = 1
  case slow = 2
  case superFast = 3
  case custom
}

enum AdvancedInputError {
  case none
  case high
  case low
  case empty
}

extension KNSelectedGasPriceType {
  func displayString() -> String {
    switch self {
    case .fast:
      return "fast"
    case .medium:
      return "regular"
    case .slow:
      return "slow"
    case .superFast:
      return "super fast"
    case .custom:
      return "custom"
    }
  }
  
  func displayTime() -> String {
    switch self {
    case .fast:
      return "30s"
    case .medium:
      return "45s"
    case .slow:
      return "10m"
    case .superFast:
      return ""
    case .custom:
      return ""
    }
  }
  
  func getGasValue() -> BigInt {
    switch self {
    case .fast:
      return KNGasCoordinator.shared.fastKNGas
    case .medium:
      return KNGasCoordinator.shared.standardKNGas
    case .slow:
      return KNGasCoordinator.shared.lowKNGas
    case .superFast:
      return KNGasCoordinator.shared.superFastKNGas
    case .custom:
      return .zero
    }
  }
  
  func getEstTime() -> Int? {
    switch self {
    case .fast:
      return KNGasCoordinator.shared.estTime?.fast
    case .medium:
      return KNGasCoordinator.shared.estTime?.standard
    case .slow:
      return KNGasCoordinator.shared.estTime?.slow
    case .superFast:
      return nil
    case .custom:
      return nil
    }
  }
  
  func getPriorityFeeValue() -> BigInt? {
    switch self {
    case .fast:
      return KNGasCoordinator.shared.fastPriorityFee
    case .medium:
      return KNGasCoordinator.shared.standardPriorityFee
    case .slow:
      return KNGasCoordinator.shared.lowPriorityFee
    case .superFast:
      return KNGasCoordinator.shared.superFastPriorityFee
    case .custom:
      return nil
    }
  }
  
  func getPriorityFeeValueString() -> String {
    guard let value = self.getPriorityFeeValue() else {
      return ""
    }
    return value.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2)
  }
  
  func getGasValueString() -> String {
    return self.getGasValue().string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 0, maxFractionDigits: 2)
  }
}

enum GasFeeSelectorPopupViewEvent {
  case infoPressed
  case gasPriceChanged(type: KNSelectedGasPriceType, value: BigInt)
  case minRatePercentageChanged(percent: CGFloat)
  case helpPressed(tag: Int)
  case useChiStatusChanged(status: Bool)
  case updateAdvancedSetting(gasLimit: String, maxPriorityFee: String, maxFee: String)
  case updateAdvancedNonce(nonce: String)
  case resetSetting
  case cancelTransactionSuccessfully(cancelTransaction: InternalHistoryTransaction)
  case cancelTransactionFailure(message: String)
  case speedupTransactionSuccessfully(speedupTransaction: InternalHistoryTransaction)
  case speedupTransactionFailure(message: String)
  case expertModeEnable(status: Bool)
}

class GasFeeSelectorPopupViewModel {
  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()
  let defaultSlippageText = "0.5"
  let defaultSlippageInputValue = 0.5
  fileprivate(set) var fast: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var medium: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var slow: BigInt = KNGasCoordinator.shared.lowKNGas
  fileprivate(set) var superFast: BigInt = KNGasCoordinator.shared.superFastKNGas

  fileprivate(set) var priorityFast: BigInt? = KNGasCoordinator.shared.fastPriorityFee
  fileprivate(set) var priorityMedium: BigInt? = KNGasCoordinator.shared.standardPriorityFee
  fileprivate(set) var prioritySlow: BigInt? = KNGasCoordinator.shared.lowPriorityFee
  fileprivate(set) var prioritySuperFast: BigInt? = KNGasCoordinator.shared.superFastPriorityFee
  fileprivate(set) var selectedType: KNSelectedGasPriceType {
    didSet {
      if self.hasChanged, self.selectedType != .custom {
        self.advancedGasLimit = nil
        self.advancedMaxPriorityFee = nil
        self.advancedMaxFee = nil
        self.advancedNonce = nil
      }
    }
  }
  fileprivate(set) var previousSelectedType: KNSelectedGasPriceType?
  fileprivate(set) var minRateType: KAdvancedSettingsMinRateType = .zeroPointFive
  fileprivate(set) var currentRate: Double
  fileprivate(set) var isSwapOption: Bool = true
  fileprivate(set) var isUseGasToken: Bool
  fileprivate(set) var isContainSippageSectionOption: Bool
  var gasLimit: BigInt
  var isAdvancedMode: Bool = false
  var currentNonce: Int = -1
  var isSpeedupMode: Bool = false {
    didSet {
      guard isSpeedupMode == true, let tx = transaction else { return }
      self.superFast = max(tx.speedupGasBigInt, KNGasCoordinator.shared.superFastKNGas)
    }
  }
  var isCancelMode: Bool = false
  var transaction: InternalHistoryTransaction?
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }

  var advancedGasLimit: String? {
    didSet {
      if self.advancedGasLimit != nil {
        self.updateSelectedType(.custom)
      }
    }
  }
  var advancedMaxPriorityFee: String? {
    didSet {
      if self.advancedMaxPriorityFee != nil {
        self.updateSelectedType(.custom)
      }
    }
  }
  var advancedMaxFee: String? {
    didSet {
      if self.advancedMaxFee != nil {
        self.updateSelectedType(.custom)
      }
    }
  }
  var advancedNonce: String? {
    didSet {
      if self.advancedNonce != nil {
        self.updateSelectedType(.custom)
      }
    }
  }
  
  var baseGasLimit: BigInt

  init(isSwapOption: Bool, gasLimit: BigInt, selectType: KNSelectedGasPriceType = .medium, currentRatePercentage: Double = 0.0, isUseGasToken: Bool = false, isContainSlippageSection: Bool = true) {
    self.isSwapOption = isSwapOption
    self.gasLimit = gasLimit
    self.baseGasLimit = gasLimit
    self.selectedType = selectType == .custom ? .medium : selectType
    self.currentRate = currentRatePercentage
    switch currentRatePercentage {
    case 0.1:
      self.minRateType = .zeroPointOne
    case 0.5:
      self.minRateType = .zeroPointFive
    case 1.0:
      self.minRateType = .onePercent
    default:
      self.minRateType = .custom(value: currentRatePercentage)
    }
    self.isUseGasToken = isUseGasToken
    self.isContainSippageSectionOption = isContainSlippageSection
  }

  var currentRateDisplay: String {
    return String(format: "%.2f", self.currentRate)
  }

  func updateMinRateValue(_ value: Double, percent: Double) {
    self.currentRate = value
    if self.minRateTypeInt == 4 {
      self.minRateType = .custom(value: percent)
    }
  }

  func updateCurrentMinRate(_ value: Double) {
    self.currentRate = value
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt, gasLimit: BigInt? = nil) -> String {
    let currentGasLimit = gasLimit ?? self.gasLimit
    let fee = gasPrice * currentGasLimit
    let feeString: String = NumberFormatUtils.gasFeeFormat(number: fee)
    
    let quoteToken = KNGeneralProvider.shared.quoteToken
    return "~ \(feeString) \(quoteToken)"
  }

  func updateGasLimit(value: BigInt) {
    self.gasLimit = value
  }

  func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
    let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
    let gasPriceAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!,
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 16),
      NSAttributedString.Key.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!,
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 12),
      NSAttributedString.Key.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: " \(text)", attributes: feeAttributes))
    return attributedString
  }

  var fastGasString: NSAttributedString {
    return self.attributedString(
      for: self.fast,
      text: NSLocalizedString("fast", value: "Fast", comment: "").uppercased()
    )
  }

  var mediumGasString: NSAttributedString {
    return self.attributedString(
      for: self.medium,
      text: NSLocalizedString("regular", value: "Regular", comment: "").uppercased()
    )
  }

  var slowGasString: NSAttributedString {
    return self.attributedString(
      for: self.slow,
      text: NSLocalizedString("slow", value: "Slow", comment: "").uppercased()
    )
  }

  var superFastGasString: NSAttributedString {
    return self.attributedString(
      for: self.superFast,
      text: NSLocalizedString("super.fast", value: "Super Fast", comment: "").uppercased()
    )
  }

  var estimateFeeSuperFastString: String {
    return self.formatFeeStringFor(gasPrice: self.superFast)
  }

  var estimateFeeFastString: String {
    return self.formatFeeStringFor(gasPrice: self.fast)
  }

  var estimateRegularFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.medium)
  }

  var estimateSlowFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.slow)
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    self.fast = fast
    self.medium = medium
    self.slow = slow
    if isSpeedupMode {
      self.superFast = max(self.transaction?.speedupGasBigInt ?? .zero, superFast)
    } else {
      self.superFast = superFast
    }

    self.priorityFast = KNGasCoordinator.shared.fastPriorityFee
    self.priorityMedium = KNGasCoordinator.shared.standardPriorityFee
    self.prioritySlow = KNGasCoordinator.shared.lowPriorityFee
    self.prioritySuperFast = KNGasCoordinator.shared.superFastPriorityFee
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    if type == .custom && self.selectedType != .custom {
      self.previousSelectedType = self.selectedType
    } else if type != .custom && self.selectedType != .custom {
      self.previousSelectedType = nil
    }
    self.selectedType = type
  }

  func updateMinRateType(_ type: KAdvancedSettingsMinRateType) {
    self.minRateType = type
  }

  var minRatePercent: Double {
    switch self.minRateType {
    case .zeroPointOne: return 0.1
    case .zeroPointFive: return 0.5
    case .onePercent: return 1.0
    case .anyRate: return 100.0
    case .custom(let value): return value
    }
  }

  var minRateTypeInt: Int {
    switch self.minRateType {
    case .zeroPointOne: return 0
    case .zeroPointFive: return 1
    case .onePercent: return 2
    case .anyRate: return 3
    case .custom: return 4
    }
  }

  var minRateDisplay: String {
    let minRate = self.currentRate * (100.0 - self.minRatePercent) / 100.0
    return self.numberFormatter.string(from: NSNumber(value: minRate))?.displayRate() ?? "0"
  }

  func valueForSelectedType(type: KNSelectedGasPriceType) -> BigInt {
    switch type {
    case .superFast:
      return self.superFast
    case .fast:
      return self.fast
    case .medium:
      return self.medium
    case .slow:
      return self.slow
    case .custom:
      if let unwrap = self.advancedMaxFee, let gasFee = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
        return gasFee
      }
      if let unwrap = self.previousSelectedType {
        return self.valueForSelectedType(type: unwrap)
      } else {
        return self.valueForSelectedType(type: .medium)
      }
    }
  }

  func valueForPrioritySelectedType(type: KNSelectedGasPriceType) -> BigInt {
    switch type {
    case .superFast:
      return self.prioritySuperFast ?? BigInt(0)
    case .fast:
      return self.priorityFast ?? BigInt(0)
    case .medium:
      return self.priorityMedium ?? BigInt(0)
    case .slow:
      return self.prioritySlow ?? BigInt(0)
    case .custom:
      if let unwrap = self.advancedMaxPriorityFee, let priorityFee = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
        return priorityFee
      }
      if let unwrap = self.previousSelectedType {
        return self.valueForPrioritySelectedType(type: unwrap)
      } else {
        return self.valueForPrioritySelectedType(type: .medium)
      }
    }
  }

  var selectedGasPriceValue: BigInt {
    return self.valueForSelectedType(type: self.selectedType)
  }

  var selectedPriorityFeeValue: BigInt {
    return self.valueForPrioritySelectedType(type: self.selectedType)
  }

  var maxPriorityFeeBigInt: BigInt {
    if let unwrap = self.advancedMaxPriorityFee {
      let value = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
      return value
    } else {
      let priorityFeeBigInt = self.selectedPriorityFeeValue
      return priorityFeeBigInt
    }
  }

  var displayMaxPriorityFee: String {
    if let unwrap =  self.advancedMaxPriorityFee {
      return unwrap
    } else {
      return self.maxPriorityFeeBigInt.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1)
    }
  }

  var advancedGasLimitBigInt: BigInt {
    if let unwrap = self.advancedGasLimit {
      return BigInt(unwrap) ?? BigInt(0)
    } else {
      return self.gasLimit
    }
  }

  var displayGasLimit: String {
    if let unwrap =  self.advancedGasLimit {
      return unwrap
    } else {
      return self.advancedGasLimitBigInt.description
    }
  }

  var displayEquivalentPriorityETHFee: String {
    let value = self.advancedGasLimitBigInt * self.maxPriorityFeeBigInt
    return value.displayRate(decimals: 18) + " \(KNGeneralProvider.shared.quoteToken)"
  }

  var maxGasFeeBigInt: BigInt {
    if let unwrap = self.advancedMaxFee {
      return unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
    } else {
      return self.selectedGasPriceValue
    }
  }

  var displayMaxGasFee: String {
    if  let unwrap = self.advancedMaxFee {
      return unwrap
    } else {
      return self.maxGasFeeBigInt.string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1)
    }
  }

  var displayAdvancedNonce: String {
    if let unwrap = self.advancedNonce {
      return unwrap
    } else {
      return self.currentNonce == -1 ? "" : "\(self.currentNonce)"
    }
  }

  var displayEquivalentMaxETHFee: String {
    let value = self.maxGasFeeBigInt * self.advancedGasLimitBigInt
    return NumberFormatUtils.gasFeeFormat(number: value) + " \(KNGeneralProvider.shared.quoteToken)"
  }
  
  var advancedGasLimitErrorStatus: AdvancedInputError {
    guard let unwrap = self.advancedGasLimit, !unwrap.isEmpty, let gasLimit = BigInt(unwrap) else {
      return .none
    }
    
    if gasLimit < BigInt(21000) {
      return .low
    } else {
      return .none
    }
  }

  var advancedNonceErrorStatus: AdvancedInputError {
    guard let unwrap = self.advancedNonce, !unwrap.isEmpty else {
      return .none
    }

    let nonceInt = Int(unwrap) ?? 0
    if nonceInt < self.currentNonce {
      return .low
    } else if nonceInt > self.currentNonce + 1 {
      return .high
    } else {
      return .none
    }
  }

  var maxPriorityErrorStatus: AdvancedInputError {
    guard let unwrap = self.advancedMaxPriorityFee, !unwrap.isEmpty else {
      return .none
    }

    let lowerLimit = KNGasCoordinator.shared.lowPriorityFee ?? BigInt(0)
    let upperLimit = (KNGasCoordinator.shared.fastPriorityFee ?? BigInt(0)) * BigInt(2)
    let maxPriorityBigInt = self.advancedMaxPriorityFee?.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)

    if maxPriorityBigInt < lowerLimit {
      return .low
    } else if maxPriorityBigInt > (BigInt(2) * upperLimit) {
      return .high
    } else {
      return .none
    }
  }

  var maxFeeErrorStatus: AdvancedInputError {
    guard let unwrap = self.advancedMaxFee, !unwrap.isEmpty else {
      return .none
    }
    let lowerLimit = self.valueForSelectedType(type: .slow).string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
    let upperLimit = self.valueForSelectedType(type: .superFast).string(units: UnitConfiguration.gasPriceUnit, minFractionDigits: 1, maxFractionDigits: 1).doubleValue
    let maxFeeDouble = self.advancedMaxFee?.doubleValue ?? 0

    if maxFeeDouble < lowerLimit {
      return .low
    } else if maxFeeDouble > upperLimit {
      return .high
    } else {
      return .none
    }
  }

  var hasChanged: Bool {
    return (self.advancedGasLimit != nil) || (self.advancedMaxPriorityFee != nil) || (self.advancedMaxFee != nil) || (self.advancedNonce != nil)
  }

  var hasNonceChaned: Bool {
    return self.advancedNonce != nil
  }

  var isAllAdvancedSettingsValid: Bool {
    if self.hasChanged {
      return true
    } else {
      return false
    }
  }

  var displayMainEstGasFee: String {
    let baseFee = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let fee = baseFee + self.maxPriorityFeeBigInt
    return String(self.formatFeeStringFor(gasPrice: fee, gasLimit: self.gasLimit).dropFirst())
  }

  var displayMainEquivalentUSD: String {
    if let usdRate = KNGeneralProvider.shared.quoteTokenPrice?.usd {
      let fee = self.maxGasFeeBigInt * self.advancedGasLimitBigInt
      let usdAmt = fee * BigInt(usdRate * pow(10.0, 18.0)) / BigInt(10).power(18)
      let valueEth = fee.displayRate(decimals: 18) + " \(KNGeneralProvider.shared.quoteToken)"
      let value = usdAmt.displayRate(decimals: 18)
      return "Max fee: \(valueEth) ~ $\(value) USD"
    }
    return ""
  }

  var isSpeedupGasValid: Bool {
    let currentValue = self.selectedGasPriceValue
    let txGas: BigInt = {
      if let normalGas = self.transaction?.transactionObject?.transactionGasPrice() {
        return normalGas * BigInt(1.1 * pow(10.0, 18.0)) / BigInt(10).power(18)
      } else if let advancedGas = self.transaction?.eip1559Transaction?.transactionGasPrice() {
        return advancedGas * BigInt(1.2 * pow(10.0, 18.0)) / BigInt(10).power(18)
      } else {
        return BigInt(0)
      }
    }()
    return txGas <= currentValue
  }
}
