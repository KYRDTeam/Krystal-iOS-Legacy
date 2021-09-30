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
  case threePercent
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

  fileprivate(set) var selectedType: KNSelectedGasPriceType
  fileprivate(set) var minRateType: KAdvancedSettingsMinRateType = .threePercent
  fileprivate(set) var currentRate: Double
  fileprivate(set) var pairToken: String = ""
  fileprivate(set) var gasLimit: BigInt
  fileprivate(set) var isSwapOption: Bool = true
  fileprivate(set) var isUseGasToken: Bool
  fileprivate(set) var isContainSippageSectionOption: Bool
  fileprivate(set) var isAdvancedMode: Bool = false

  var advancedGasLimit: String = ""
  var advancedMaxPriorityFee: String = ""
  var advancedMaxFee: String = ""
  var advancedNonce: String = ""

  init(isSwapOption: Bool, gasLimit: BigInt, selectType: KNSelectedGasPriceType = .medium, currentRatePercentage: Double = 0.0, isUseGasToken: Bool = false, isContainSlippageSection: Bool = true) {
    self.isSwapOption = isSwapOption
    self.gasLimit = gasLimit
    self.selectedType = selectType == .custom ? .medium : selectType
    self.currentRate = currentRatePercentage
    self.minRateType = currentRatePercentage == 1.0 ? .threePercent : .custom(value: currentRatePercentage)
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
    if self.minRateTypeInt == 2 {
      self.minRateType = .custom(value: percent)
    }
  }

  func updateCurrentMinRate(_ value: Double) {
    self.currentRate = value
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee = gasPrice * self.gasLimit
    let feeString: String = fee.displayRate(decimals: 18)
    let quoteToken = KNGeneralProvider.shared.quoteToken
    return "~ \(feeString) \(quoteToken)"
  }

  func updateGasLimit(value: BigInt) {
    self.gasLimit = value
  }

  var advancedSettingsHeight: CGFloat {
    return self.isSwapOption ? 504 : 250
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
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    self.selectedType = type
  }

  func updateMinRateType(_ type: KAdvancedSettingsMinRateType) {
    self.minRateType = type
  }

  var minRatePercent: Double {
    switch self.minRateType {
    case .threePercent: return 1.0
    case .anyRate: return 100.0
    case .custom(let value): return value
    }
  }

  var minRateTypeInt: Int {
    switch self.minRateType {
    case .threePercent: return 0
    case .anyRate: return 1
    case .custom: return 2
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
    default:
      return BigInt(0)
    }
  }
  
  var selectedGasPriceValue: BigInt {
    return self.valueForSelectedType(type: self.selectedType)
  }
  
  var displayMaxPriorityFee: String {
    let baseFeeBigInt = KNGasCoordinator.shared.basePrice.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
    return ""
  }
}

enum GasFeeSelectorPopupViewEvent {
  case infoPressed
  case gasPriceChanged(type: KNSelectedGasPriceType, value: BigInt)
  case minRatePercentageChanged(percent: CGFloat)
  case helpPressed
  case useChiStatusChanged(status: Bool)
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

  @IBOutlet weak var threePercentButton: UIButton!
  @IBOutlet weak var threePercentTextLabel: UILabel!

  @IBOutlet weak var customButton: UIButton!
  @IBOutlet weak var customTextLabel: UILabel!
  @IBOutlet weak var customRateTextField: UITextField!
  @IBOutlet weak var customRateContainerView: UIView!

  @IBOutlet weak var transactionWillBeRevertedTextLabel: UILabel!
  @IBOutlet weak var sendSwapDivideLineView: UIView!
  @IBOutlet weak var slippageRateSectionHeighContraint: NSLayoutConstraint!
  @IBOutlet weak var slippageSectionContainerView: UIView!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  @IBOutlet weak var advancedModeContainerView: UIView!
  @IBOutlet weak var popupContainerHeightContraint: NSLayoutConstraint!
  
  @IBOutlet weak var advancedGasLimitField: UITextField!
  @IBOutlet weak var advancedPriorityFeeField: UITextField!
  @IBOutlet weak var advancedMaxFeeField: UITextField!
  @IBOutlet weak var advancedNonceField: UITextField!
  @IBOutlet weak var equivalentPriorityETHFeeLabel: UILabel!
  @IBOutlet weak var equivalentMaxETHFeeLabel: UILabel!
  
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

    self.estimateFeeNoteLabel.text = "Select higher gas price to accelerate your transaction processing time".toBeLocalised()
    self.gasFeeGweiTextLabel.text = NSLocalizedString("gas.fee.gwei", value: "GAS fee (Gwei)", comment: "")
    self.customRateTextField.delegate = self
    self.customRateTextField.text = self.viewModel.minRateTypeInt == 2 ? self.viewModel.currentRateDisplay : ""
    self.sendSwapDivideLineView.isHidden = !self.viewModel.isSwapOption
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
    if self.viewModel.isContainSippageSectionOption {
      self.slippageRateSectionHeighContraint.constant = 160
      self.slippageSectionContainerView.isHidden = false
    } else {
      self.slippageRateSectionHeighContraint.constant = 0
      self.slippageSectionContainerView.isHidden = true
    }
    self.setupSegmentedControl()
    segmentedControl.highlightSelectedSegment()
    self.updateUIForMode(true)
    self.advancedGasLimitField.text = self.viewModel.gasLimit.description
  }

  func updateMinRateCustomErrorShown(_ isShown: Bool) {
    let borderColor = isShown ? UIColor.Kyber.strawberry : UIColor.clear
    self.customRateContainerView.rounded(color: borderColor, width: isShown ? 1.0 : 0.0, radius: 8)
  }

  var isMinRateValid: Bool {
    if case .threePercent = self.viewModel.minRateType { return true }
    let custom = self.customRateTextField.text ?? ""
    return !custom.isEmpty
  }

  fileprivate func updateMinRateUIs() {
    guard self.viewModel.isSwapOption else { return }
    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.threePercentButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.minRateTypeInt == 0 ? selectedWidth : normalWidth,
      radius: self.threePercentButton.frame.height / 2.0
    )

    self.customButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.minRateTypeInt == 2 ? selectedWidth : normalWidth,
      radius: self.customButton.frame.height / 2.0
    )
    self.customRateTextField.isEnabled = self.viewModel.minRateTypeInt == 2

    self.stillProceedIfRateGoesDownTextLabel.text = String(
      format: NSLocalizedString("still.proceed.if.rate.goes.down.by", value: "Still proceed if %@ goes down by:", comment: ""),
      self.viewModel.pairToken
    )
    self.transactionWillBeRevertedTextLabel.text = "Your transaction will revert if the price changes unfavorably by more than this percentage"
    self.updateMinRateCustomErrorShown(!self.isMinRateValid)
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

  fileprivate func updateUIForMode(_ isInit: Bool = false) {
    self.advancedModeContainerView.isHidden = !self.viewModel.isAdvancedMode
    if !isInit {
      UIView.animate(withDuration: 0.2) {
        if self.viewModel.isAdvancedMode {
          self.contentViewTopContraint.constant -= 230
          self.popupContainerHeightContraint.constant += 230
        } else {
          self.contentViewTopContraint.constant += 230
          self.popupContainerHeightContraint.constant -= 230
        }
      }
    }
  }

  @IBAction func gasFeeButtonTapped(_ sender: UIButton) {
    let selectType = KNSelectedGasPriceType(rawValue: sender.tag)!
    self.viewModel.updateSelectedType(selectType)
    self.delegate?.gasFeeSelectorPopupViewController(self, run: .gasPriceChanged(type: selectType, value: self.viewModel.valueForSelectedType(type: selectType)))
    self.updateGasPriceUIs()
  }

  @IBAction func customRateButtonTapped(_ sender: UIButton) {
    let minRateType = sender.tag == 1 ? KAdvancedSettingsMinRateType.custom(value: self.viewModel.currentRate) : KAdvancedSettingsMinRateType.threePercent
    self.viewModel.updateMinRateType(minRateType)
    self.customRateTextField.text = sender.tag == 1 ? self.viewModel.currentRateDisplay : ""
    self.customRateTextField.isEnabled = sender.tag == 1
    self.delegate?.gasFeeSelectorPopupViewController(self, run: .minRatePercentageChanged(percent: 1.0))
    self.updateMinRateUIs()
  }

  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.delegate?.gasFeeSelectorPopupViewController(self, run: .helpPressed)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    self.customRateTextField.resignFirstResponder()
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

  @IBAction func segmentedControlDidChange(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    self.viewModel.isAdvancedMode = sender.selectedSegmentIndex == 1
    self.updateUIForMode()
  }
  
  @IBAction func gasLimitChgAmountButtonTapped(_ sender: UIButton) {
    let isIncrease = sender.tag == 1
    var currentGasLimit = Int(self.advancedGasLimitField.text ?? "") ?? 0
    if isIncrease {
      currentGasLimit += 1000
      self.viewModel.advancedGasLimit = String(currentGasLimit)
    } else {
      currentGasLimit -= 1000
    }
    if currentGasLimit > 0 {
      self.viewModel.advancedGasLimit = String(currentGasLimit)
      self.advancedGasLimitField.text = String(currentGasLimit)
    }
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
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    if textField == self.advancedGasLimitField {
      self.viewModel.advancedGasLimit = text
      return true
    } else if textField == self.advancedPriorityFeeField {
      self.viewModel.advancedMaxPriorityFee = text
      return true
    } else if textField == self.advancedMaxFeeField {
      self.viewModel.advancedMaxFee = text
      return true
    } else if textField == self.advancedNonceField {
      self.viewModel.advancedNonce = text
      return true
    } else {
      let number = text.replacingOccurrences(of: ",", with: ".")
      let value: Double? = number.isEmpty ? 0 : Double(number)
      let maxMinRatePercent: Double = 100.0
      if let val = value, val >= 0, val <= maxMinRatePercent {
        textField.text = text
        self.viewModel.updateMinRateType(.custom(value: val))
        self.updateMinRateUIs()
        self.delegate?.gasFeeSelectorPopupViewController(self, run: .minRatePercentageChanged(percent: CGFloat(val)))
      }
      return false
    }
  }
}
