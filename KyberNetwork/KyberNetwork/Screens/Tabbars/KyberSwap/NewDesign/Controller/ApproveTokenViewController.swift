//
//  ApproveTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/25/20.
//

import UIKit
import BigInt

protocol ApproveTokenViewModel {
  func getFee() -> BigInt
  func getFeeString() -> String
  func getFeeUSDString() -> String
  var subTitleText: String { get }
  var token: TokenObject? { get }
  var remain: BigInt { get }
  var address: String { get }
  var state: Bool { get }
  var symbol: String { get }
  var toAddress: String? { get }
  var tokenAddress: String? { get }
  var gasLimit: BigInt { get set }
  var value: BigInt { get set }
  var selectedGasPriceType: KNSelectedGasPriceType { get set }
  var advancedGasLimit: String? { get set }
  var advancedMaxPriorityFee: String? { get set }
  var advancedMaxFee: String? { get set }
  var advancedNonce: String? { get set }
  var customSetting: ConfirmAdvancedSetting { get }
  var showEditSettingButton: Bool { get set }
  var gasPrice: BigInt { get set }
  var headerTitle: String { get set }
  func resetAdvancedSettings()
  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType)
}

class ApproveTokenViewModelForTokenObject: ApproveTokenViewModel {
  var showEditSettingButton: Bool = false
  var gasLimit: BigInt = KNGasConfiguration.approveTokenGasLimitDefault
  var value: BigInt = Constants.maxValueBigInt
  var headerTitle: String = "Approve Token"

  var tokenAddress: String? {
    return self.address
  }

  let token: TokenObject?
  let remain: BigInt
  var gasPrice: BigInt = KNGasCoordinator.shared.defaultKNGas
  var toAddress: String?

  func getFee() -> BigInt {
    let fee = self.gasPrice * self.gasLimit
    return fee
  }

  func getFeeString() -> String {
    let fee = self.getFee()
    return "\(NumberFormatUtils.gasFeeFormat(number: fee)) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getFeeUSDString() -> String {
    guard let tokenPrice = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let feeUSD = self.getFee() * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    return "~ \(feeUSD.displayRate(decimals: 18)) USD"
  }

  var subTitleText: String {
    return String(format: "You need to approve Krystal to spend %@", self.token?.symbol.uppercased() ?? "")
  }

  var address: String {
    return self.token?.address ?? ""
  }
  
  var state: Bool {
    return false
  }
  
  var symbol: String {
    return self.token?.symbol ?? ""
  }
  
  var selectedGasPriceType: KNSelectedGasPriceType = .medium
  
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
  
  var customSetting: ConfirmAdvancedSetting {
    return ConfirmAdvancedSetting(gasPrice: self.gasPrice.description, gasLimit: self.gasLimit.description, advancedGasLimit: self.advancedGasLimit, advancedPriorityFee: self.advancedMaxPriorityFee, avancedMaxFee: self.advancedMaxFee, advancedNonce: Int(self.advancedNonce ?? ""))
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
  
  func resetAdvancedSettings() {
    self.advancedGasLimit = nil
    self.advancedMaxPriorityFee = nil
    self.advancedMaxFee = nil
    self.advancedNonce = nil
    if self.selectedGasPriceType == .custom {
      self.selectedGasPriceType = .medium
    }
  }

  init(token: TokenObject, res: BigInt) {
    self.token = token
    self.remain = res
  }
}

class ApproveTokenViewModelForTokenAddress: ApproveTokenViewModel {
  var showEditSettingButton: Bool = false
  var gasLimit: BigInt = KNGasConfiguration.approveTokenGasLimitDefault
  var value: BigInt = Constants.maxValueBigInt
  var headerTitle: String = "Approve Token"

  var tokenAddress: String? {
    return self.address
  }

  var token: TokenObject?
  let address: String
  let remain: BigInt
  var gasPrice: BigInt = KNGasCoordinator.shared.defaultKNGas
  let state: Bool
  let symbol: String
  var toAddress: String?

  init(address: String, remain: BigInt, state: Bool, symbol: String) {
    self.address = address
    self.remain = remain
    self.state = state
    self.symbol = symbol
  }

  func getFee() -> BigInt {
    let fee = self.gasPrice * self.gasLimit
    return fee
  }

  func getFeeString() -> String {
    let fee = self.getFee()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getFeeUSDString() -> String {
    guard let tokenPrice = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let feeUSD = self.getFee() * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    return "~ \(feeUSD.displayRate(decimals: 18)) USD"
  }

  var subTitleText: String {
    return "You need to approve Krystal to spend \(self.symbol.uppercased())"
  }
  
  var selectedGasPriceType: KNSelectedGasPriceType = .medium
  
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
  
  var customSetting: ConfirmAdvancedSetting {
    return ConfirmAdvancedSetting(gasPrice: self.gasPrice.description, gasLimit: self.gasLimit.description, advancedGasLimit: self.advancedGasLimit, advancedPriorityFee: self.advancedMaxPriorityFee, avancedMaxFee: self.advancedMaxFee, advancedNonce: Int(self.advancedNonce ?? ""))
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
  
  func resetAdvancedSettings() {
    self.advancedGasLimit = nil
    self.advancedMaxPriorityFee = nil
    self.advancedMaxFee = nil
    self.advancedNonce = nil
    if self.selectedGasPriceType == .custom {
      self.selectedGasPriceType = .medium
    }
  }
}

protocol ApproveTokenViewControllerDelegate: class {
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt, gasLimit: BigInt)
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt)
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: String, value: BigInt)
  func approveTokenViewControllerDidSelectGasSetting(_ controller: ApproveTokenViewController, gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?)
}

class ApproveTokenViewController: KNBaseViewController {
  @IBOutlet weak var headerTitle: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var contractAddressLabel: UILabel!
  @IBOutlet weak var gasFeeTitleLabel: UILabel!
  @IBOutlet weak var gasFeeLabel: UILabel!
  @IBOutlet weak var gasFeeEstUSDLabel: UILabel!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var editIcon: UIImageView!
  @IBOutlet weak var editLabel: UILabel!
  @IBOutlet weak var editButton: UIButton!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainLabel: UILabel!
  var onDismiss: (() -> Void)? = nil
  var viewModel: ApproveTokenViewModel
  let transitor = TransitionDelegate()
  weak var delegate: ApproveTokenViewControllerDelegate?
  
  var approveValue: BigInt {
    return self.viewModel.value
  }
  
  var selectedGasPrice: BigInt {
    return self.viewModel.gasPrice
  }

  init(viewModel: ApproveTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ApproveTokenViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupChainInfo()
    self.gasFeeLabel.text = self.viewModel.getFeeString()
    self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
    self.cancelButton.rounded(radius: 16)
    self.confirmButton.rounded(radius: 16)
    self.descriptionLabel.text = self.viewModel.subTitleText
    let address = self.viewModel.toAddress ?? KNGeneralProvider.shared.proxyAddress
    self.contractAddressLabel.text = address
    
    if let tokenAddress = self.viewModel.tokenAddress {
      self.delegate?.approveTokenViewControllerGetEstimateGas(self, tokenAddress: tokenAddress, value: self.viewModel.value)
    }
    
    if !self.viewModel.showEditSettingButton {
      self.editIcon.isHidden = true
      self.editLabel.isHidden = true
      self.editButton.isHidden = true
    }
    self.headerTitle.text = self.viewModel.headerTitle
  }
  
  func setupChainInfo() {
    chainIcon.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainLabel.text = KNGeneralProvider.shared.currentChain.chainName()
  }

  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    let ethBalance = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    guard self.viewModel.getFee() < ethBalance else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: String(format: Strings.insufficientTokenForNetworkFee, KNGeneralProvider.shared.quoteTokenObject.symbol)
      )
      return
    }
    if let token = self.viewModel.token {
      self.delegate?.approveTokenViewControllerDidApproved(self, token: token, remain: self.viewModel.remain, gasLimit: self.viewModel.gasLimit)
    } else {
      self.delegate?.approveTokenViewControllerDidApproved(self, address: self.viewModel.address, remain: self.viewModel.remain, state: self.viewModel.state, toAddress: self.viewModel.toAddress, gasLimit: self.viewModel.gasLimit)
    }
    self.dismiss(animated: true, completion: {
      
    })
  }

  @IBAction func editButtonTapped(_ sender: Any) {
    self.delegate?.approveTokenViewControllerDidSelectGasSetting(self, gasLimit: self.viewModel.gasLimit, baseGasLimit: self.viewModel.gasLimit, selectType: self.viewModel.selectedGasPriceType, advancedGasLimit: self.viewModel.advancedGasLimit, advancedPriorityFee: self.viewModel.advancedMaxPriorityFee, advancedMaxFee: self.viewModel.advancedMaxFee, advancedNonce: self.viewModel.advancedNonce)
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    onDismiss?()
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    onDismiss?()
    self.dismiss(animated: true, completion: nil)
  }
  
  fileprivate func updateGasFeeUI() {
    self.gasFeeLabel.text = self.viewModel.getFeeString()
    self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
  }
  
  func coordinatorDidUpdateGasLimit(_ gas: BigInt) {
    self.viewModel.gasLimit = gas
    guard self.isViewLoaded else { return }
    updateGasFeeUI()
  }
  
  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.selectedGasPriceType = .custom
    self.updateGasFeeUI()
  }
  
  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }
  
  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.selectedGasPriceType = type
    self.viewModel.gasPrice = value
    self.viewModel.updateSelectedGasPriceType(type)
    self.updateGasFeeUI()
    self.viewModel.resetAdvancedSettings()
  }
}

extension ApproveTokenViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 380
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
