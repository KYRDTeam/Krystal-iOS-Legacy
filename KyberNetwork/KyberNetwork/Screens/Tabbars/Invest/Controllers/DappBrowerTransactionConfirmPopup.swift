//
//  DappBrowerTransactionConfirmPopup.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 05/01/2022.
//

import UIKit
import BigInt

struct ConfirmAdvancedSetting {
  let gasPrice: String
  let gasLimit: String
  let advancedGasLimit: String?
  let advancedPriorityFee: String?
  let avancedMaxFee: String?
  let advancedNonce: Int?
}

class  DappBrowerTransactionConfirmViewModel {
  let transaction: SignTransactionObject
  let url: String
  let onSign: ((ConfirmAdvancedSetting) -> Void)
  let onCancel: (() -> Void)
  let onChangeGasFee: ((BigInt, BigInt, KNSelectedGasPriceType, String?, String?, String?, String?) -> Void)
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt
  fileprivate(set) var gasLimit: BigInt
  fileprivate(set) var baseGasLimit: BigInt
  
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

  init(transaction: SignTransactionObject, url: String, onSign: @escaping ((ConfirmAdvancedSetting) -> Void), onCancel: @escaping (() -> Void), onChangeGasFee: @escaping ((BigInt, BigInt, KNSelectedGasPriceType, String?, String?, String?, String?) -> Void)) {
    self.transaction = transaction
    self.url = url
    self.onSign = onSign
    self.onCancel = onCancel
    self.onChangeGasFee = onChangeGasFee
    self.gasPrice = BigInt(transaction.gasPrice) ?? BigInt(0)
    self.gasLimit = BigInt(transaction.gasLimit) ?? BigInt(0)
    self.baseGasLimit = self.gasLimit
  }

  var displayFromAddress: String {
    return self.transaction.from
  }

  var valueBigInt: BigInt {
    return BigInt(self.transaction.value) ?? BigInt(0)
  }
  
  var displayValue: String {
    let prefix = self.valueBigInt.isZero ? "" : "-"
    return prefix + "\(self.valueBigInt.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken)"
  }
  
  var displayValueUSD: String {
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.valueBigInt * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    
    let valueString: String = usd.displayRate(decimals: 18)
    return "≈ $\(valueString)"
  }
  
  var transactionFeeETHString: String {
    let fee: BigInt = {
      return self.gasPrice * self.gasLimit
    }()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  var transactionFeeUSDString: String {
    let fee: BigInt = {
      return self.gasPrice * self.gasLimit
    }()

    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = fee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var transactionGasPriceString: String {
    let gasPriceText = self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: self.gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }

  var imageIconURL: String {
    return "https://www.google.com/s2/favicons?sz=128&domain=\(self.url)/"
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

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
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
  
  var customSetting: ConfirmAdvancedSetting {
    return ConfirmAdvancedSetting(gasPrice: self.gasPrice.description, gasLimit: self.gasLimit.description, advancedGasLimit: self.advancedGasLimit, advancedPriorityFee: self.advancedMaxPriorityFee, avancedMaxFee: self.advancedMaxFee, advancedNonce: Int(self.advancedNonce ?? ""))
  }
}

class DappBrowerTransactionConfirmPopup: KNBaseViewController {
  @IBOutlet weak var siteIconImageView: UIImageView!
  @IBOutlet weak var siteURLLabel: UILabel!
  @IBOutlet weak var fromAddressLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var equivalentValueLabel: UILabel!
  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  private let viewModel: DappBrowerTransactionConfirmViewModel
  
  let transitor = TransitionDelegate()
  
  init(viewModel: DappBrowerTransactionConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: DappBrowerTransactionConfirmPopup.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupUI()
  }
  
  
  @IBAction func tapOutsidePopup(_ sender: Any) {
    self.dismiss(animated: true) {
      self.viewModel.onCancel()
    }
  }
  
  @IBAction func tapInsidePopup(_ sender: Any) {
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onCancel()
    }
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.viewModel.onSign(self.viewModel.customSetting)
    }
  }
  
  @IBAction func transactionFeeHelpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
  
  @IBAction func editSettingButtonTapped(_ sender: UIButton) {
    self.viewModel.onChangeGasFee(self.viewModel.gasLimit, self.viewModel.baseGasLimit, self.viewModel.selectedGasPriceType, self.viewModel.advancedGasLimit, self.viewModel.advancedMaxPriorityFee, self.viewModel.advancedMaxFee, self.viewModel.advancedNonce)
  }

  fileprivate func updateGasFeeUI() {
    self.equivalentValueLabel.text = self.viewModel.displayValueUSD
    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    self.gasPriceTextLabel.text = self.viewModel.transactionGasPriceString
  }

  private func setupUI() {
    self.fromAddressLabel.text = self.viewModel.displayFromAddress
    self.valueLabel.text = self.viewModel.displayValue
    self.updateGasFeeUI()
    self.siteURLLabel.text = self.viewModel.url
    UIImage.loadImageIconWithCache(viewModel.imageIconURL) { image in
      self.siteIconImageView.image = image
    }
    self.confirmButton.rounded(radius: 16)
    self.cancelButton.rounded(radius: 16)
  }

  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.updateGasFeeUI()
  }

  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.updateSelectedGasPriceType(.custom)
    self.updateGasFeeUI()
  }

  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }
}

extension DappBrowerTransactionConfirmPopup: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 600
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
