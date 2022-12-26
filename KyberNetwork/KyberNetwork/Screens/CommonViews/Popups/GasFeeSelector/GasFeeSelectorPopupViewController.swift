//
//  GasFeeSelectorPopupViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/4/20.
//

import UIKit
import BigInt
import APIKit
import JSONRPCKit
import TransactionModule

protocol GasFeeSelectorPopupViewControllerDelegate: class {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent)
}

class GasFeeSelectorPopupViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
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
  let web3Client = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
  
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
    self.getLatestNonce()
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
    self.contentViewHeight.constant = getPopupHeight()
    self.configSlippageUI()
    self.estimateFeeNoteLabel.text = "Select higher gas price to accelerate your transaction processing time".toBeLocalised()
    self.gasFeeGweiTextLabel.text = NSLocalizedString("gas.fee.gwei", value: "GAS fee (Gwei)", comment: "")
    self.customRateTextField.delegate = self
    self.customRateTextField.text = self.viewModel.minRateTypeInt == 4 ? self.viewModel.currentRateDisplay + "%" : ""
    self.customRateTextField.setPlaceholder(text: "Input", color: UIColor(named: "navButtonBgColor")!)
    self.advancedCustomRateTextField.text = self.viewModel.minRateTypeInt == 4 ? self.viewModel.currentRateDisplay + "%" : ""
    self.advancedCustomRateTextField.setPlaceholder(text: "Input", color: UIColor(named: "navButtonBgColor")!)
    
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
    case .none, .empty:
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
    case .none, .empty:
      self.maxFeeErrorLabel.text = ""
      self.advancedMaxFeeField.textColor = UIColor(named: "textWhiteColor")
      self.equivalentMaxETHFeeLabel.textColor = UIColor(named: "normalTextColor")
      self.maxFeeAccessoryLabel.textColor = UIColor(named: "textWhiteColor")
    }

    switch self.viewModel.advancedGasLimitErrorStatus {
    case .low:
      self.advancedGasLimitField.textColor = UIColor(named: "textRedColor")
      self.gasLimitErrorLabel.text = "Gas limit must be at least \(Constants.lowLimitGas)"
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
    self.transactionWillBeRevertedTextLabel.text = "Your transaction will revert if the price changes unfavorably by more than this percentage."
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
    self.customRateTextField.text = ""
    self.customRateTextField.setPlaceholder(text: "Input", color: UIColor(named: "navButtonBgColor")!)
    self.advancedCustomRateTextField.text = ""
    self.advancedCustomRateTextField.setPlaceholder(text: "Input", color: UIColor(named: "navButtonBgColor")!)
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
    self.customRateButtonTapped(self.secondOptionSippageButton)
    self.customRateTextField.text = ""
    self.advancedCustomRateTextField.text = ""
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
            self.speedupTransaction(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
            return
          }

          if self.viewModel.isCancelMode, let original = self.viewModel.transaction, let tx = original.eip1559Transaction {
            self.cancelTransaction(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
            return
          }
        } else {
          if self.viewModel.selectedType == .custom {
            if self.viewModel.isAllAdvancedSettingsValid {
              self.delegate?.gasFeeSelectorPopupViewController(self, run: .updateAdvancedSetting(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee))
            }
          } else {
            self.delegate?.gasFeeSelectorPopupViewController(self, run: .gasPriceChanged(type: self.viewModel.selectedType, value: self.viewModel.valueForSelectedType(type: self.viewModel.selectedType)))
            print("[GasSelector][EIP1559][Select] \(self.viewModel.selectedType.rawValue)")
          }
        }
      } else {
        let gasLimit = self.advancedGasLimitField.text ?? ""
        let maxPriorityFee = self.advancedPriorityFeeField.text ?? ""
        let maxFee = self.advancedMaxFeeField.text ?? ""
        if self.viewModel.isSpeedupMode || self.viewModel.isCancelMode {
          let gasLimitBigInt = BigInt(gasLimit) ?? BigInt(0)
          let maxFeeBigInt = maxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? BigInt(0)
          
          if self.viewModel.isSpeedupMode {
            self.speedupTransaction(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
            print("[GasSelector][Legacy][Speedup] \(gasLimitBigInt.description) \(maxFeeBigInt.description)")
          }

          if self.viewModel.isCancelMode {
            self.cancelTransaction(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
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
  
  func speedupTransaction(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    guard let transaction = viewModel.transaction else { return }
    
    let processor: TransactionProcessor = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return EthereumEIP1559TransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
      } else {
        return EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
      }
    }()
    
    let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
    
    processor.speedUp(address: viewModel.currentAddress, transaction: transaction, gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxGasFee: maxFee) { result in
      switch result {
      case .success(let hash):
        savedTx?.state = .speedup
        savedTx?.hash = hash
        if let unwrapped = savedTx {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .speedupTransactionSuccessfully(speedupTransaction: transaction))
          KNNotificationUtil.postNotification(
            for: kTransactionDidUpdateNotificationKey,
            object: unwrapped,
            userInfo: nil
          )
            TransactionManager.onTransactionStatusUpdated(hash: unwrapped.txHash, status: unwrapped.state)
        }
      case .failure(let error):
        var errorMessage = "Cancel failed"
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
            errorMessage = message
          }
        }
        self.delegate?.gasFeeSelectorPopupViewController(self, run: .speedupTransactionFailure(message: errorMessage))
      }
    }
  }
  
  func cancelTransaction(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    guard let transaction = viewModel.transaction else { return }
    
    let processor: TransactionProcessor = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return EthereumEIP1559TransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
      } else {
        return EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
      }
    }()
    
    let gasLimit = self.advancedGasLimitField.text ?? ""
    let maxPriorityFee = self.advancedPriorityFeeField.text ?? ""
    let maxFee = self.advancedMaxFeeField.text ?? ""
    
    let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
    
    processor.cancel(address: viewModel.currentAddress, transaction: transaction, gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxGasFee: maxFee) { result in
      switch result {
      case .success(let hash):
        savedTx?.state = .cancel
        savedTx?.type = .transferETH
        savedTx?.transactionSuccessDescription = "-0 ETH"
        savedTx?.hash = hash
        if let unwrapped = savedTx {
          self.delegate?.gasFeeSelectorPopupViewController(self, run: .cancelTransactionSuccessfully(cancelTransaction: unwrapped))
          KNNotificationUtil.postNotification(
            for: kTransactionDidUpdateNotificationKey,
            object: unwrapped,
            userInfo: nil
          )
            TransactionManager.onTransactionStatusUpdated(hash: unwrapped.txHash, status: unwrapped.state)
        }
      case .failure(let error):
        var errorMessage = "Cancel failed"
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
            errorMessage = message
          }
        }
        self.delegate?.gasFeeSelectorPopupViewController(self, run: .cancelTransactionFailure(message: errorMessage))
      }
    }
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
  
  @IBAction func closeWasTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
}

extension GasFeeSelectorPopupViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return min(650, UIScreen.main.bounds.height - 120)
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
    
    if let text = textField.text {
      textField.text = text.replacingOccurrences(of: "%", with: "")
    }
    textField.setPlaceholder(text: "\(self.viewModel.minRatePercent)", color: UIColor(named: "navButtonBgColor")!)
    self.viewModel.updateMinRateType(.custom(value: self.viewModel.currentRate))
    self.configSlippageUIByType(.custom(value: self.viewModel.currentRate))
  
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    guard textField == self.customRateTextField || textField == self.advancedCustomRateTextField else {
      return
    }
    var text = textField.text ?? self.viewModel.defaultSlippageText
    if text.isEmpty {
      text = self.viewModel.defaultSlippageText
    }
    let shouldFocus = !text.isEmpty
    self.updateFocusForView(view: textField, isFocus: shouldFocus)
    let maxMinRatePercent: Double = 50.0
    let stringFormatter = StringFormatter()
    let value = stringFormatter.decimal(with: text)?.doubleValue
    if let val = value {
      self.advancedCustomRateTextField.text = text
      self.customRateTextField.text = text
      self.viewModel.updateCurrentMinRate(val)
      self.viewModel.updateMinRateType(.custom(value: val))
      self.updateMinRateUIs()
      if val >= 0, val <= maxMinRatePercent {
        self.delegate?.gasFeeSelectorPopupViewController(self, run: .minRatePercentageChanged(percent: CGFloat(val)))
      } else {
        self.delegate?.gasFeeSelectorPopupViewController(self, run: .minRatePercentageChanged(percent: CGFloat(self.viewModel.defaultSlippageInputValue)))
      }
      self.configSlippageUIByType(.custom(value: val))
      textField.text = text + "%"
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

extension GasFeeSelectorPopupViewController {
  
  func getLatestNonce() {
    let address = viewModel.currentAddress.addressString
    let currentChain = KNGeneralProvider.shared.currentChain
    web3Client.getTransactionCount(for: address) { [weak self] result in
      switch result {
      case .success(let nonce):
        NonceCache.shared.updateNonce(address: address, chain: currentChain, nonce: nonce)
        self?.coordinatorDidUpdateCurrentNonce(nonce)
      default:
        return
      }
    }
  }
  
}
