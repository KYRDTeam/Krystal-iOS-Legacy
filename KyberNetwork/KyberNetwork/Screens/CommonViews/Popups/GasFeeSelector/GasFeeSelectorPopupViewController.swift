//
//  GasFeeSelectorPopupViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/4/20.
//

import UIKit
import BigInt

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
}

enum KAdvancedSettingsMinRateType {
  case zeroPointOne
  case zeroPointFive
  case onePercent
  case anyRate
  case custom(value: Double)
}

class GasFeeSelectorPopupViewModel {
  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()

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
  fileprivate(set) var minRateType: KAdvancedSettingsMinRateType = .zeroPointOne
  fileprivate(set) var currentRate: Double
  fileprivate(set) var pairToken: String = ""
  fileprivate(set) var gasLimit: BigInt
  fileprivate(set) var isSwapOption: Bool = true
  fileprivate(set) var isUseGasToken: Bool
  fileprivate(set) var isContainSippageSectionOption: Bool
  fileprivate(set) var isAdvancedMode: Bool = false
  var currentNonce: Int = -1
  var isSpeedupMode: Bool = false
  var isCancelMode: Bool = false
  var transaction: InternalHistoryTransaction?

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

  func updatePairToken(_ value: String) {
    self.pairToken = value
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
    let feeString: String = fee.displayRate(decimals: 18)
    let quoteToken = KNGeneralProvider.shared.quoteToken
    return "~ \(feeString) \(quoteToken)"
  }

  func updateGasLimit(value: BigInt) {
    self.gasLimit = value
  }

  var advancedSettingsHeight: CGFloat {
    return 650
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
    self.superFast = superFast

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
    return value.displayRate(decimals: 18) + " \(KNGeneralProvider.shared.quoteToken)"
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

enum GasFeeSelectorPopupViewEvent {
  case infoPressed
  case gasPriceChanged(type: KNSelectedGasPriceType, value: BigInt)
  case minRatePercentageChanged(percent: CGFloat)
  case helpPressed(tag: Int)
  case useChiStatusChanged(status: Bool)
  case updateAdvancedSetting(gasLimit: String, maxPriorityFee: String, maxFee: String)
  case updateAdvancedNonce(nonce: String)
  case speedupTransaction(transaction: EIP1559Transaction, original: InternalHistoryTransaction)
  case cancelTransaction(transaction: EIP1559Transaction, original: InternalHistoryTransaction)
  case speedupTransactionLegacy(legacyTransaction: SignTransactionObject, original: InternalHistoryTransaction)
  case cancelTransactionLegacy(legacyTransaction: SignTransactionObject, original: InternalHistoryTransaction)
  case resetSetting
}

protocol GasFeeSelectorPopupViewControllerDelegate: class {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent)
}

class GasFeeSelectorPopupViewController: KNBaseViewController {
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!

  @IBOutlet weak var gasFeeGweiTextLabel: UILabel!

  @IBOutlet weak var superFastGasButton: UIButton!
  @IBOutlet weak var superFastGasValueLabel: UILabel!
  @IBOutlet weak var superFastEstimateFeeLabel: UILabel!

  @IBOutlet weak var fasGasValueLabel: UILabel!
  @IBOutlet weak var fasGasButton: UIButton!
  @IBOutlet weak var fastEstimateFeeLabel: UILabel!

  @IBOutlet weak var mediumGasValueLabel: UILabel!
  @IBOutlet weak var mediumGasButton: UIButton!
  @IBOutlet weak var regularEstimateFeeLabel: UILabel!

  @IBOutlet weak var slowGasValueLabel: UILabel!
  @IBOutlet weak var slowGasButton: UIButton!
  @IBOutlet weak var slowEstimateFeeLabel: UILabel!

  @IBOutlet weak var estimateFeeNoteLabel: UILabel!
  @IBOutlet weak var stillProceedIfRateGoesDownTextLabel: UILabel!

  @IBOutlet weak var firstOptionAdvanceSlippageButton: UIButton!
  @IBOutlet weak var secondOptionAdvanceSlippageButton: UIButton!
  @IBOutlet weak var thirdOptionAdvanceSlippageButton: UIButton!
  @IBOutlet weak var customRateTextField: UITextField!
  @IBOutlet weak var advancedStillProceedIfRateGoesDownTextLabel: UILabel!
  @IBOutlet weak var advancedCustomRateTextField: UITextField!
  @IBOutlet weak var transactionWillBeRevertedTextLabel: UILabel!
  @IBOutlet weak var sendSwapDivideLineView: UIView!
  @IBOutlet weak var slippageRateSectionHeighContraint: NSLayoutConstraint!
  @IBOutlet weak var slippageSectionContainerView: UIView!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  @IBOutlet weak var advancedModeContainerView: UIScrollView!
  @IBOutlet weak var popupContainerHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var advancedGasLimitField: UITextField!
  @IBOutlet weak var advancedPriorityFeeField: UITextField!
  @IBOutlet weak var advancedMaxFeeField: UITextField!
  @IBOutlet weak var advancedNonceField: UITextField!
  @IBOutlet weak var equivalentPriorityETHFeeLabel: UILabel!
  @IBOutlet weak var equivalentMaxETHFeeLabel: UILabel!
  @IBOutlet weak var maxPriorityFeeErrorLabel: UILabel!
  @IBOutlet weak var maxFeeErrorLabel: UILabel!
  @IBOutlet weak var mainGasFeeLabel: UILabel!
  @IBOutlet weak var mainEquivalentUSDLabel: UILabel!
  @IBOutlet weak var nonceErrorLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var customNonceTitleLabel: UILabel!
  @IBOutlet weak var customNonceContainerView: UIView!
  @IBOutlet weak var advancedSlippageContainerView: UIView!
  @IBOutlet weak var advancedSlippageDivideView: UIView!
  @IBOutlet weak var advancedScrollViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var basicContainerViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var estGasFeeTitleLabel: UILabel!
  @IBOutlet weak var advancedMaxFeeTitleTopContraint: NSLayoutConstraint!
  @IBOutlet weak var advancedPriorityFeeTItleLabel: UILabel!
  @IBOutlet weak var advancedPriorityFeeHelpButton: UIButton!
  @IBOutlet weak var advancedPriorityFeeContainerView: UIView!
  @IBOutlet weak var gasLimitHelpButton: UIButton!
  @IBOutlet weak var maxFeeHelpButton: UIButton!
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!
  @IBOutlet weak var priorityAccessoryLabel: UILabel!
  @IBOutlet weak var maxFeeAccessoryLabel: UILabel!
  @IBOutlet weak var gasLimitErrorLabel: UILabel!
  @IBOutlet weak var customNonceHelpButton: UIButton!
  @IBOutlet weak var firstOptionSlippageButton: UIButton!
  @IBOutlet weak var secondOptionSippageButton: UIButton!
  @IBOutlet weak var thirdOptionSlippageButton: UIButton!
  @IBOutlet weak var slippageHintLabelTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var warningSlippageLabel: UILabel!
  @IBOutlet weak var advanceSlippageHintLabelTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var advanceWarningSlippageLabel: UILabel!
  let viewModel: GasFeeSelectorPopupViewModel
  let transitor = TransitionDelegate()

  weak var delegate: GasFeeSelectorPopupViewControllerDelegate?

  init(viewModel: GasFeeSelectorPopupViewModel) {
    self.viewModel = viewModel
    super.init(nibName: GasFeeSelectorPopupViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configUI()
  }

  func updateFocusForView(view: UIView, isFocus: Bool) {
    if isFocus {
      view.rounded(color: UIColor(named: "buttonBackgroundColor")!, width: 1.0, radius: 14.0)
      view.backgroundColor = UIColor(named: "innerContainerBgColor")!
    } else {
      view.rounded(color: UIColor(named: "navButtonBgColor")!, width: 1.0, radius: 14.0)
      view.backgroundColor = .clear
    }
  }

  func configSlippageUI() {
    // for basic mode
    self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: false)
    self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.customRateTextField, isFocus: false)
    //for advance mode
    self.updateFocusForView(view: self.firstOptionAdvanceSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.secondOptionAdvanceSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.thirdOptionAdvanceSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: false)

    switch self.viewModel.minRatePercent {
    case 0.1:
      self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: true)
      self.updateFocusForView(view: self.firstOptionAdvanceSlippageButton, isFocus: true)
    case 0.5:
      self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: true)
      self.updateFocusForView(view: self.secondOptionAdvanceSlippageButton, isFocus: true)
    case 1.0:
      self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: true)
      self.updateFocusForView(view: self.thirdOptionAdvanceSlippageButton, isFocus: true)
    default:
      self.updateFocusForView(view: self.customRateTextField, isFocus: true)
      self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: true)
    }
    self.updateSlippageHintLabel()
  }

  func updateSlippageHintLabel() {
    var shouldShowWarningLabel = false
    var warningText = ""
    var warningColor = UIColor(named: "warningColor")!
    if self.viewModel.minRatePercent <= 0.1 {
      shouldShowWarningLabel = true
      warningText = "Your transaction may fail".toBeLocalised()
    } else if self.viewModel.minRatePercent > 50.0 {
      shouldShowWarningLabel = true
      warningText = "Enter a valid slippage percentage".toBeLocalised()
      warningColor = UIColor(named: "textRedColor")!
    } else if self.viewModel.minRatePercent >= 10 {
      shouldShowWarningLabel = true
      warningText = "Your transaction may be frontrun".toBeLocalised()
    }
    self.warningSlippageLabel.text = warningText
    self.advanceWarningSlippageLabel.text = warningText
    self.warningSlippageLabel.textColor = warningColor
    self.advanceWarningSlippageLabel.textColor = warningColor
    self.slippageHintLabelTopConstraint.constant = shouldShowWarningLabel ? CGFloat(46) : CGFloat(18)
    self.advanceSlippageHintLabelTopConstraint.constant = shouldShowWarningLabel ? CGFloat(46) : CGFloat(18)
  }

  func configSlippageUIByType(_ type: KAdvancedSettingsMinRateType) {
    // for basic mode
    self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: false)
    self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.customRateTextField, isFocus: false)
    //for advance mode
    self.updateFocusForView(view: self.firstOptionAdvanceSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.secondOptionAdvanceSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.thirdOptionAdvanceSlippageButton, isFocus: false)
    self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: false)
    switch type {
    case .zeroPointOne:
      self.updateFocusForView(view: self.firstOptionSlippageButton, isFocus: true)
      self.updateFocusForView(view: self.firstOptionAdvanceSlippageButton, isFocus: true)
    case .zeroPointFive:
      self.updateFocusForView(view: self.secondOptionSippageButton, isFocus: true)
      self.updateFocusForView(view: self.secondOptionAdvanceSlippageButton, isFocus: true)
    case .onePercent:
      self.updateFocusForView(view: self.thirdOptionSlippageButton, isFocus: true)
      self.updateFocusForView(view: self.thirdOptionAdvanceSlippageButton, isFocus: true)
    default:
      self.updateFocusForView(view: self.customRateTextField, isFocus: true)
      self.updateFocusForView(view: self.advancedCustomRateTextField, isFocus: true)
    }
    self.updateSlippageHintLabel()
  }

  func configUI() {
    self.configSlippageUI()
    self.estimateFeeNoteLabel.text = "Select higher gas price to accelerate your transaction processing time".toBeLocalised()
    self.gasFeeGweiTextLabel.text = NSLocalizedString("gas.fee.gwei", value: "GAS fee (Gwei)", comment: "")
    self.customRateTextField.delegate = self
    self.customRateTextField.text = self.viewModel.minRateTypeInt == 4 ? self.viewModel.currentRateDisplay : ""
    self.customRateTextField.attributedPlaceholder = NSAttributedString(string: "Input", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "navButtonBgColor")!])
    self.advancedCustomRateTextField.text = self.viewModel.minRateTypeInt == 4 ? self.viewModel.currentRateDisplay : ""
    self.advancedCustomRateTextField.attributedPlaceholder = NSAttributedString(string: "Input", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "navButtonBgColor")!])
    self.sendSwapDivideLineView.isHidden = !self.viewModel.isSwapOption
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
    if self.viewModel.isContainSippageSectionOption {
      self.slippageRateSectionHeighContraint.constant = 160
      self.slippageSectionContainerView.isHidden = false
      self.advancedSlippageContainerView.isHidden = false
      self.advancedSlippageDivideView.isHidden = false
    } else {
      self.slippageRateSectionHeighContraint.constant = 0
      self.slippageSectionContainerView.isHidden = true
      self.advancedSlippageContainerView.isHidden = true
      self.advancedSlippageDivideView.isHidden = true
    }
    self.segmentedControl.selectedSegmentIndex = self.viewModel.selectedType == .custom ? 1 : 0
    self.viewModel.isAdvancedMode = self.viewModel.selectedType == .custom
    self.setupSegmentedControl()
    segmentedControl.highlightSelectedSegment()
    self.updateUIForMode()
    self.updateUIAdvancedSetting()
    self.updateUIForMainGasFee()
    self.updateUIForCustomNonce()
  }

  fileprivate func updateUIAdvancedSetting() {
    if !KNGeneralProvider.shared.isUseEIP1559 {
      self.estGasFeeTitleLabel.isHidden = true
      self.mainGasFeeLabel.isHidden = true
      self.mainEquivalentUSDLabel.isHidden = true
      self.basicContainerViewTopContraint.constant = 20
      self.advancedScrollViewTopContraint.constant = 20
      self.advancedMaxFeeTitleTopContraint.constant = 30
      self.advancedPriorityFeeTItleLabel.isHidden = true
      self.advancedPriorityFeeHelpButton.isHidden = true
      self.advancedPriorityFeeContainerView.isHidden = true
      self.maxPriorityFeeErrorLabel.isHidden = true
    }

    if self.viewModel.isSpeedupMode || self.viewModel.isCancelMode {
      self.firstButton.setTitle("Cancel", for: .normal)
      self.secondButton.setTitle("Confirm", for: .normal)
    }
    self.advancedGasLimitField.text = self.viewModel.displayGasLimit
    self.advancedPriorityFeeField.text = self.viewModel.displayMaxPriorityFee
    self.equivalentPriorityETHFeeLabel.text = self.viewModel.displayEquivalentPriorityETHFee
    self.advancedMaxFeeField.text = self.viewModel.displayMaxGasFee
    self.equivalentMaxETHFeeLabel.text = self.viewModel.displayEquivalentMaxETHFee
    self.advancedNonceField.text = self.viewModel.displayAdvancedNonce

    switch self.viewModel.maxPriorityErrorStatus {
    case .low:
      self.maxPriorityFeeErrorLabel.text = "Max Priority Fee is low for current network conditions"
      self.maxPriorityFeeErrorLabel.textColor = UIColor(named: "textRedColor")
      self.advancedPriorityFeeField.textColor = UIColor(named: "textRedColor")
      self.priorityAccessoryLabel.textColor = UIColor(named: "textRedColor")
      self.equivalentPriorityETHFeeLabel.textColor = UIColor(named: "textRedColor")?.withAlphaComponent(0.5)
    case .high:
      self.maxPriorityFeeErrorLabel.text = "Max Priority Fee is higher than necessary"
      self.maxPriorityFeeErrorLabel.textColor = UIColor(named: "textRedColor")
      self.advancedPriorityFeeField.textColor = UIColor(named: "textRedColor")
      self.priorityAccessoryLabel.textColor = UIColor(named: "textRedColor")
      self.equivalentPriorityETHFeeLabel.textColor = UIColor(named: "textRedColor")?.withAlphaComponent(0.5)
    case .none:
      self.maxPriorityFeeErrorLabel.text = ""
      self.advancedPriorityFeeField.textColor = UIColor(named: "textWhiteColor")
      self.equivalentPriorityETHFeeLabel.textColor = UIColor(named: "normalTextColor")
      self.priorityAccessoryLabel.textColor = UIColor(named: "textWhiteColor")
    }

    switch self.viewModel.maxFeeErrorStatus {
    case .low:
      self.maxFeeErrorLabel.text = "Max Fee is low for current network conditions"
      self.maxFeeErrorLabel.textColor = UIColor(named: "textRedColor")
      self.advancedMaxFeeField.textColor = UIColor(named: "textRedColor")
      self.maxFeeAccessoryLabel.textColor = UIColor(named: "textRedColor")
      self.equivalentMaxETHFeeLabel.textColor = UIColor(named: "textRedColor")?.withAlphaComponent(0.5)
    case .high:
      self.maxFeeErrorLabel.text = "Max Fee is higher than necessary"
      self.maxFeeErrorLabel.textColor = UIColor(named: "textRedColor")
      self.advancedMaxFeeField.textColor = UIColor(named: "textRedColor")
      self.maxFeeAccessoryLabel.textColor = UIColor(named: "textRedColor")
      self.equivalentMaxETHFeeLabel.textColor = UIColor(named: "textRedColor")?.withAlphaComponent(0.5)
    case .none:
      self.maxFeeErrorLabel.text = ""
      self.advancedMaxFeeField.textColor = UIColor(named: "textWhiteColor")
      self.equivalentMaxETHFeeLabel.textColor = UIColor(named: "normalTextColor")
      self.maxFeeAccessoryLabel.textColor = UIColor(named: "textWhiteColor")
    }

    switch self.viewModel.advancedGasLimitErrorStatus {
    case .low:
      self.advancedGasLimitField.textColor = UIColor(named: "textRedColor")
      self.gasLimitErrorLabel.text = "Gas limit must be at least 21000"
    default:
      self.advancedGasLimitField.textColor = UIColor(named: "textWhiteColor")
      self.gasLimitErrorLabel.text = ""
    }
    self.updateUIForCustomNonce()

    if self.viewModel.isSpeedupMode || self.viewModel.isCancelMode {
      self.titleLabel.text = self.viewModel.isSpeedupMode ? "Speedup Transaction" : "Cancel Transaction"
      self.advancedSlippageContainerView.isHidden = true
      self.slippageSectionContainerView.isHidden = true
      self.advancedSlippageDivideView.isHidden = true
      self.sendSwapDivideLineView.isHidden = true
    }

  }

  fileprivate func updateMinRateUIs() {
    guard self.viewModel.isSwapOption else { return }
    self.stillProceedIfRateGoesDownTextLabel.text = String(
      format: NSLocalizedString("still.proceed.if.rate.goes.down.by", value: "Still proceed if %@ goes down by:", comment: ""),
      self.viewModel.pairToken
    )
    self.transactionWillBeRevertedTextLabel.text = "Your transaction will revert if the price changes unfavorably by more than this percentage"

    self.advancedStillProceedIfRateGoesDownTextLabel.text = String(
      format: NSLocalizedString("still.proceed.if.rate.goes.down.by", value: "Still proceed if %@ goes down by:", comment: ""),
      self.viewModel.pairToken
    )
    self.contentView.updateConstraints()
    self.contentView.layoutSubviews()
  }

  fileprivate func setupSegmentedControl() {
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
  }

  fileprivate func updateGasPriceUIs() {
    self.superFastGasValueLabel.attributedText = self.viewModel.superFastGasString
    self.fasGasValueLabel.attributedText = self.viewModel.fastGasString
    self.mediumGasValueLabel.attributedText = self.viewModel.mediumGasString
    self.slowGasValueLabel.attributedText = self.viewModel.slowGasString

    self.superFastEstimateFeeLabel.text = self.viewModel.estimateFeeSuperFastString
    self.fastEstimateFeeLabel.text = self.viewModel.estimateFeeFastString
    self.regularEstimateFeeLabel.text = self.viewModel.estimateRegularFeeString
    self.slowEstimateFeeLabel.text = self.viewModel.estimateSlowFeeString

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.superFastGasButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.selectedType == .superFast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.fasGasButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.mediumGasButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.mediumGasButton.frame.height / 2.0
    )

    self.slowGasButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasButton.frame.height / 2.0
    )

    self.contentView.updateConstraints()
    self.contentView.layoutSubviews()
  }

  fileprivate func updateUIForMode() {
    self.advancedModeContainerView.isHidden = !self.viewModel.isAdvancedMode
  }

  fileprivate func updateUIForMainGasFee() {
    self.mainGasFeeLabel.text = self.viewModel.displayMainEstGasFee
    self.mainEquivalentUSDLabel.text = self.viewModel.displayMainEquivalentUSD
  }

  fileprivate func updateUIForCustomNonce() {
    guard self.isViewLoaded else { return }
    guard !(self.viewModel.isSpeedupMode || self.viewModel.isCancelMode) else {
      self.customNonceTitleLabel.isHidden = true
      self.customNonceContainerView.isHidden = true
      self.nonceErrorLabel.isHidden = true
      self.customNonceHelpButton.isHidden = true
      return
    }
    guard self.viewModel.currentNonce != -1 else {
      self.advancedNonceField.text = ""
      self.nonceErrorLabel.isHidden = true
      return
    }
    guard let customNonce = self.viewModel.advancedNonce else {
      self.advancedNonceField.text = "\(self.viewModel.currentNonce)"
      self.advancedNonceField.textColor = UIColor(named: "textWhiteColor")
      self.nonceErrorLabel.isHidden = true
      return
    }
    self.advancedNonceField.text = customNonce
    switch self.viewModel.advancedNonceErrorStatus {
    case .low:
      self.advancedNonceField.textColor = UIColor(named: "textRedColor")
      self.nonceErrorLabel.isHidden = false
      self.nonceErrorLabel.text = "Nonce is too low"
    case .high:
      self.advancedNonceField.textColor = UIColor(named: "textRedColor")
      self.nonceErrorLabel.isHidden = false
      self.nonceErrorLabel.text = "Nonce is too high"
    default:
      self.advancedNonceField.textColor = UIColor(named: "textWhiteColor")
      self.nonceErrorLabel.isHidden = true
      self.nonceErrorLabel.text = ""
    }
  }

  @IBAction func gasFeeButtonTapped(_ sender: UIButton) {
    let selectType = KNSelectedGasPriceType(rawValue: sender.tag)!
    self.viewModel.updateSelectedType(selectType)
    self.viewModel.gasLimit = self.viewModel.baseGasLimit
    self.updateGasPriceUIs()
    self.updateUIForMainGasFee()
    self.updateUIAdvancedSetting()
  }

  @IBAction func customRateButtonTapped(_ sender: UIButton) {
    var minRateType = KAdvancedSettingsMinRateType.custom(value: self.viewModel.currentRate)
    switch sender.tag {
    case 0:
      minRateType = KAdvancedSettingsMinRateType.zeroPointOne
    case 1:
      minRateType = KAdvancedSettingsMinRateType.zeroPointFive
    default:
      minRateType = KAdvancedSettingsMinRateType.onePercent
    }
    self.viewModel.updateMinRateType(minRateType)
    self.delegate?.gasFeeSelectorPopupViewController(self, run: .minRatePercentageChanged(percent: self.viewModel.minRatePercent))
    self.updateMinRateUIs()
    self.configSlippageUI()
  }

  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.delegate?.gasFeeSelectorPopupViewController(self, run: .helpPressed(tag: sender.tag))
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: {
    })
  }

  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    if sender.location(in: self.contentView).y <= 70 {
      self.dismiss(animated: true, completion: nil)
    } else {
      self.contentView.endEditing(true)
    }
  }

  @IBAction func firstButtonTapped(_ sender: UIButton) {
    guard !(self.viewModel.isCancelMode || self.viewModel.isSpeedupMode) else {
      self.dismiss(animated: true, completion: {
      })
      return
    }
    self.gasFeeButtonTapped(self.mediumGasButton)
  }

  @IBAction func secondButtonTapped(_ sender: UIButton) {
    guard self.viewModel.selectedGasPriceValue >= self.viewModel.selectedPriorityFeeValue else {
      self.showErrorTopBannerMessage(message: "Max priority fee should be lower than max fee")
      return
    }

    if self.viewModel.isSpeedupMode || self.viewModel.isCancelMode {
      guard self.viewModel.isSpeedupGasValid else {
        self.showSpeedupCancelErrorAlert()
        return
      }
    }
    self.dismiss(animated: true, completion: {
      if KNGeneralProvider.shared.isUseEIP1559 {
        let gasLimit = self.advancedGasLimitField.text ?? ""
        let maxPriorityFee = self.advancedPriorityFeeField.text ?? ""
        let maxFee = self.advancedMaxFeeField.text ?? ""
        if self.viewModel.isSpeedupMode || self.viewModel.isCancelMode {
          if self.viewModel.isSpeedupMode, let original = self.viewModel.transaction, let tx = original.eip1559Transaction {
            self.delegate?.gasFeeSelectorPopupViewController(self, run: .speedupTransaction(transaction: tx.toSpeedupTransaction(gasLimit: gasLimit, priorityFee: maxPriorityFee, maxGasFee: maxFee), original: original))
            print("[GasSelector][EIP1559][Speedup] \(gasLimit) \(maxPriorityFee) \(maxFee)")
            return
          }

          if self.viewModel.isCancelMode, let original = self.viewModel.transaction, let tx = original.eip1559Transaction {
            self.delegate?.gasFeeSelectorPopupViewController(self, run: .cancelTransaction(transaction: tx.toCancelTransaction(gasLimit: gasLimit, priorityFee: maxPriorityFee, maxGasFee: maxFee), original: original))
            print("[GasSelector][EIP1559][Cancel] \(gasLimit) \(maxPriorityFee) \(maxFee)")
            return
          }
        } else {
          if self.viewModel.selectedType == .custom {
            if self.viewModel.isAllAdvancedSettingsValid {
              self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedSetting(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee))
            }
            print("[GasSelector][EIP1559][Select] \(gasLimit) \(maxPriorityFee) \(maxFee)")
          } else {
            self.delegate?.gasFeeSelectorPopupViewController(self, run: .gasPriceChanged(type: self.viewModel.selectedType, value: self.viewModel.valueForSelectedType(type: self.viewModel.selectedType)))
            print("[GasSelector][EIP1559][Select] \(self.viewModel.selectedType.rawValue)")
          }
        }
      } else {
        let gasLimit = self.advancedGasLimitField.text ?? ""
        let maxFee = self.advancedMaxFeeField.text ?? ""
        if self.viewModel.isSpeedupMode || self.viewModel.isCancelMode {
          let gasLimitBigInt = BigInt(gasLimit) ?? BigInt(0)
          let maxFeeBigInt = maxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
          if self.viewModel.isSpeedupMode, let original = self.viewModel.transaction, let tx = original.transactionObject {
            self.delegate?.gasFeeSelectorPopupViewController(self, run: .speedupTransactionLegacy(legacyTransaction: tx.toSpeedupTransaction(gasPrice: maxFeeBigInt.description, gasLimit: gasLimitBigInt.description), original: original))
            print("[GasSelector][Legacy][Speedup] \(gasLimitBigInt.description) \(maxFeeBigInt.description)")
          }

          if self.viewModel.isCancelMode, let original = self.viewModel.transaction, let tx = original.transactionObject {
            self.delegate?.gasFeeSelectorPopupViewController(self, run: .cancelTransactionLegacy(legacyTransaction: tx.toCancelTransaction(gasPrice: maxFeeBigInt.description, gasLimit: gasLimitBigInt.description), original: original))
            print("[GasSelector][Legacy][Cancel] \(gasLimitBigInt.description) \(maxFeeBigInt.description)")
          }
        } else {
          if self.viewModel.selectedType == .custom {
            if self.viewModel.isAllAdvancedSettingsValid {
              self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedSetting(gasLimit: gasLimit, maxPriorityFee: "", maxFee: maxFee))
            }
            print("[GasSelector][Legacy][Select] \(gasLimit) \(maxFee)")
          } else {
            self.delegate?.gasFeeSelectorPopupViewController(self, run: .gasPriceChanged(type: self.viewModel.selectedType, value: self.viewModel.valueForSelectedType(type: self.viewModel.selectedType)))
            print("[GasSelector][Legacy][Select] \(self.viewModel.selectedType.rawValue)")
          }
        }
      }

      if let nonceString = self.advancedNonceField.text,
         self.viewModel.selectedType == .custom,
         self.viewModel.hasNonceChaned {
        self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedNonce(nonce: nonceString))
      }
    })
  }

  func showSpeedupCancelErrorAlert() {
    let message = KNGeneralProvider.shared.isUseEIP1559 ? "The max fee must be 20% higher than the current max fee" : "The max fee must be 10% higher than the current max fee"
    self.showWarningTopBannerMessage(
      with: "Invalid input",
      message: message
    )
  }

  func coordinatorDidUpdateGasLimit(_ value: BigInt) {
    self.viewModel.updateGasLimit(value: value)
    self.updateGasPriceUIs()
  }

  func coordinatorDidUpdateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    self.viewModel.updateGasPrices(fast: fast, medium: medium, slow: slow, superFast: superFast)
    self.updateGasPriceUIs()
  }

  func coordinatorDidUpdateMinRate(_ value: Double) {
    self.viewModel.updateCurrentMinRate(value)
    self.updateMinRateUIs()
  }

  func coordinatorDidUpdateUseGasTokenState(_ status: Bool) {
    //TODO: remove all gas token logic
  }

  func coordinatorDidUpdateCurrentNonce(_ nonce: Int) {
    self.viewModel.currentNonce = nonce
    self.updateUIForCustomNonce()
  }

  @IBAction func segmentedControlDidChange(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    self.viewModel.isAdvancedMode = sender.selectedSegmentIndex == 1
    self.updateUIForMode()
    self.updateGasPriceUIs()
  }

  @IBAction func gasLimitChgAmountButtonTapped(_ sender: UIButton) {
    let isIncrease = sender.tag == 1
    var currentGasLimit = Int(self.advancedGasLimitField.text ?? "") ?? 0
    if isIncrease {
      currentGasLimit += 1000
    } else {
      currentGasLimit -= 1000
    }
    if currentGasLimit > 0 {
      self.viewModel.advancedGasLimit = String(currentGasLimit)
    }
    self.updateUIAdvancedSetting()
    self.updateUIForMainGasFee()
  }

  @IBAction func maxPriorityFeeChangeAmountButtonTapped(_ sender: UIButton) {
    let isIncrease = sender.tag == 1
    var currentValue = self.advancedPriorityFeeField.text?.doubleValue ?? 0.0
    if isIncrease {
      currentValue += 0.5
    } else {
      currentValue -= 0.5
    }
    if currentValue > 0 {
      self.viewModel.advancedMaxPriorityFee = NumberFormatterUtil.shared.displayPercentage(from: currentValue)
    }
    self.updateUIAdvancedSetting()
    self.updateUIForMainGasFee()
  }

  @IBAction func maxGasFeeChangeAmountButtonTapped(_ sender: UIButton) {
    let isIncrease = sender.tag == 1
    var currentValue = self.advancedMaxFeeField.text?.doubleValue ?? 0.0
    if isIncrease {
      currentValue += 0.5
    } else {
      currentValue -= 0.5
    }
    if currentValue > 0 {
      self.viewModel.advancedMaxFee = NumberFormatterUtil.shared.displayPercentage(from: currentValue)
    }
    self.updateUIAdvancedSetting()
    self.updateUIForMainGasFee()
  }

  @IBAction func customNonceChangeButtonTapped(_ sender: UIButton) {
    let isIncrease = sender.tag == 1
    var currentValue = Int(self.advancedNonceField.text ?? "") ?? 0
    if isIncrease {
      currentValue += 1
    } else {
      currentValue -= 1
    }
    if currentValue > 0 {
      self.viewModel.advancedNonce = String(currentValue)
    }
    self.updateUIForCustomNonce()
  }
}

extension GasFeeSelectorPopupViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.viewModel.advancedSettingsHeight
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension GasFeeSelectorPopupViewController: UITextFieldDelegate {

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    guard textField == self.customRateTextField || textField == self.advancedCustomRateTextField else {
      return true
    }
    textField.text = "\(self.viewModel.currentRate)"
    self.viewModel.updateMinRateType(.custom(value: self.viewModel.currentRate))
    self.configSlippageUIByType(.custom(value: self.viewModel.currentRate))
  
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    guard textField == self.customRateTextField || textField == self.advancedCustomRateTextField else {
      return
    }
    var text = textField.text ?? "0.0"
    if text.isEmpty {
      text = "0.0"
    }
    let shouldFocus = !text.isEmpty
    self.updateFocusForView(view: textField, isFocus: shouldFocus)
    let maxMinRatePercent: Double = 100.0
    let number = text.replacingOccurrences(of: ",", with: ".")
    let value: Double? = number.isEmpty ? 0 : Double(number)
    if let val = value, val >= 0, val <= maxMinRatePercent {
      self.advancedCustomRateTextField.text = text
      self.customRateTextField.text = text
      self.viewModel.updateCurrentMinRate(val)
      self.viewModel.updateMinRateType(.custom(value: val))
      self.updateMinRateUIs()
      self.delegate?.gasFeeSelectorPopupViewController(self, run: .minRatePercentageChanged(percent: CGFloat(val)))
      self.configSlippageUIByType(.custom(value: val))
    }
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let number = text.replacingOccurrences(of: ",", with: ".")
    let value: Double? = number.isEmpty ? 0 : Double(number)
    if textField == self.advancedGasLimitField {
      if value != nil {
        self.viewModel.advancedGasLimit = text
        self.updateUIAdvancedSetting()
        self.updateUIForMainGasFee()
      }
      return false
    } else if textField == self.advancedPriorityFeeField {
      if value != nil {
        self.viewModel.advancedMaxPriorityFee = text
        self.updateUIAdvancedSetting()
        self.updateUIForMainGasFee()
      }
      return false
    } else if textField == self.advancedMaxFeeField {
      if value != nil {
        self.viewModel.advancedMaxFee = text
        self.updateUIAdvancedSetting()
        self.updateUIForMainGasFee()
      }
      return false
    } else if textField == self.advancedNonceField {
      self.viewModel.advancedNonce = text
      self.updateUIForCustomNonce()
      return false
    } else {
      guard !text.isEmpty else {
        textField.rounded(color: UIColor(named: "error_red_color")!, width: 1.0, radius: 14.0)
        return true
      }
      textField.rounded(color: UIColor(named: "buttonBackgroundColor")!, width: 1.0, radius: 14.0)
      return true
    }
  }
}
