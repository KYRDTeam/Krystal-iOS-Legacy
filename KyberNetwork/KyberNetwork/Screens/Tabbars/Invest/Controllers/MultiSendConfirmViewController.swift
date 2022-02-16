//
//  MultiSendConfirmViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 16/02/2022.
//

import UIKit
import BigInt

enum MultiSendConfirmViewEvent {
  case openGasPriceSelect(gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?)
  case dismiss
  case confirm
  case showAddresses
}

protocol MultiSendConfirmViewControllerDelegate: class {
  func multiSendConfirmVieController(_ controller: MultiSendConfirmViewController, run event: MultiSendConfirmViewEvent)
}

class MultiSendConfirmViewModel {
  let sendItems: [MultiSendItem]
  
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
  
  init(sendItems: [MultiSendItem], gasPrice: BigInt, gasLimit: BigInt, baseGasLimit: BigInt) {
    self.sendItems = sendItems
    self.gasPrice = gasPrice
    self.gasLimit = gasLimit
    self.baseGasLimit = baseGasLimit
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
}

class MultiSendConfirmViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  
  @IBOutlet weak var addressCountLabel: UILabel!
  @IBOutlet weak var amountTableView: UITableView!
  @IBOutlet weak var totalAmountLabel: UILabel!
  
  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  
  let transitor = TransitionDelegate()
  let viewModel: MultiSendConfirmViewModel
  weak var delegate: MultiSendConfirmViewControllerDelegate?
  
  init(viewModel: MultiSendConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: MultiSendConfirmViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.updateUI()
    self.updateGasFeeUI()
  }
  
  fileprivate func updateUI() {
    self.addressCountLabel.text = "\(self.viewModel.sendItems.count)"
  }
  
  fileprivate func updateGasFeeUI() {
    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    self.gasPriceTextLabel.text = self.viewModel.transactionGasPriceString
  }
  
  @IBAction func showAddressButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.multiSendConfirmVieController(self, run: .dismiss)
    }
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true) {
      self.delegate?.multiSendConfirmVieController(self, run: .dismiss)
    }
  }

  @IBAction func editGasFeeButtonTapped(_ sender: UIButton) {
    self.delegate?.multiSendConfirmVieController(self, run: .openGasPriceSelect(gasLimit: self.viewModel.gasLimit, baseGasLimit: self.viewModel.baseGasLimit, selectType: self.viewModel.selectedGasPriceType, advancedGasLimit: self.viewModel.advancedGasLimit, advancedPriorityFee: self.viewModel.advancedMaxPriorityFee, advancedMaxFee: self.viewModel.advancedMaxFee, advancedNonce: self.viewModel.advancedNonce))
  }
  
  @IBAction func showAddressesButtonTapped(_ sender: UIButton) {
    self.delegate?.multiSendConfirmVieController(self, run: .showAddresses)
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
  
  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    
    self.updateGasFeeUI()
    self.viewModel.resetAdvancedSettings()
  }
}

extension MultiSendConfirmViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 555
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
