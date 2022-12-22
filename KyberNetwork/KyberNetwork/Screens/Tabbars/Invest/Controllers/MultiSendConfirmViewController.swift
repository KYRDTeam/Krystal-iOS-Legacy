//
//  MultiSendConfirmViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 16/02/2022.
//

import UIKit
import BigInt
import Utilities

enum MultiSendConfirmViewEvent {
  case openGasPriceSelect(gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?)
  case dismiss
  case confirm(setting: ConfirmAdvancedSetting)
  case showAddresses(items: [MultiSendItem])
}

protocol MultiSendConfirmViewControllerDelegate: class {
  func multiSendConfirmVieController(_ controller: MultiSendConfirmViewController, run event: MultiSendConfirmViewEvent)
}

class MultiSendConfirmViewModel {
  let sendItems: [MultiSendItem]
  
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt
  fileprivate(set) var gasLimit: BigInt
  fileprivate(set) var l1Fee: BigInt
  fileprivate(set) var baseGasLimit: BigInt
  fileprivate(set) var transferAmountDataSource: [String] = []
  fileprivate(set) var totalValueString: String = ""
  
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
  
    init(sendItems: [MultiSendItem], gasPrice: BigInt, gasLimit: BigInt, baseGasLimit: BigInt, l1Fee: BigInt) {
        self.sendItems = sendItems
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.baseGasLimit = baseGasLimit
        self.l1Fee = l1Fee
  }
  
  var transactionFeeETHString: String {
    let fee: BigInt = {
        return self.gasPrice * self.gasLimit + self.l1Fee
    }()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  var transactionFeeUSDString: String {
    let fee: BigInt = {
      return self.gasPrice * self.gasLimit + self.l1Fee
    }()

    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = fee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var transactionGasPriceString: String {
    let gasPriceText = self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 5
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
  
  func reloadDataSource() {
    let tokens = self.sendItems.map { element in
      return element.2
    }
    
    let removeDuplicateSet = Set(tokens)
    var tokenAmountStrings: [String] = []
    var totalUSDAmt = BigInt.zero
    removeDuplicateSet.forEach { element in
      let items = self.sendItems.filter { item in
        return item.2 == element
      }
      var balance = BigInt(0)
      items.forEach { item in
        balance += item.1
      }
      let string = balance.string(
        decimals: element.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(element.decimals, 5)
      ).prefix(15)
      let displayString = "\(string) \(element.symbol)"
      tokenAmountStrings.append(displayString)
      var usdAmt = BigInt.zero
      if let usdRate = KNTrackerRateStorage.shared.getPriceWithAddress(element.address) {
        usdAmt = balance * BigInt(usdRate.usd * pow(10.0, 18.0)) / BigInt(10).power(element.decimals)
      }
      totalUSDAmt += usdAmt
      
    }
    self.transferAmountDataSource = tokenAmountStrings
    self.totalValueString = "~ \(totalUSDAmt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: DecimalNumber.usd)) USD"
  }
  
  var customSetting: ConfirmAdvancedSetting {
    return ConfirmAdvancedSetting(gasPrice: self.gasPrice.description, gasLimit: self.gasLimit.description, advancedGasLimit: self.advancedGasLimit, advancedPriorityFee: self.advancedMaxPriorityFee, avancedMaxFee: self.advancedMaxFee, advancedNonce: Int(self.advancedNonce ?? ""))
  }
}

class MultiSendConfirmViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainLabel: UILabel!
  @IBOutlet weak var addressCountLabel: UILabel!
  @IBOutlet weak var amountTableView: UITableView!
  @IBOutlet weak var totalAmountLabel: UILabel!
  
  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var confirmButton: UIButton!
  
  @IBOutlet weak var amountTableViewHeightContraint: NSLayoutConstraint!
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
    
    self.setupChainInfo()
    self.amountTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    self.amountTableView.rowHeight = 28

    self.updateUI()
    self.updateGasFeeUI()
    self.backButton.rounded(radius: 16)
    self.confirmButton.rounded(radius: 16)
    MixPanelManager.track("multi_send_confirm_pop_up_open", properties: ["screenid": "multi_send_confirm_pop_up"])
  }
  
  func setupChainInfo() {
    chainIcon.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainLabel.text = KNGeneralProvider.shared.currentChain.chainName()
  }
  
  fileprivate func updateUI() {
    self.addressCountLabel.text = "\(self.viewModel.sendItems.count)"
    self.viewModel.reloadDataSource()
    self.amountTableViewHeightContraint.constant = CGFloat(self.viewModel.transferAmountDataSource.count * 28)
    self.totalAmountLabel.text = self.viewModel.totalValueString
  }
  
  fileprivate func updateGasFeeUI() {
    guard self.isViewLoaded else { return }
    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    self.gasPriceTextLabel.text = self.viewModel.transactionGasPriceString
  }
  
  @IBAction func showAddressButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.multiSendConfirmVieController(self, run: .dismiss)
    }
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.multiSendConfirmVieController(self, run: .confirm(setting: self.viewModel.customSetting))
    }
    MixPanelManager.track("multisend_confirm", properties: ["screenid": "multi_send"])
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
    self.delegate?.multiSendConfirmVieController(self, run: .showAddresses(items: self.viewModel.sendItems))
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

extension MultiSendConfirmViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.transferAmountDataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "cell",
      for: indexPath
    )

    let cm = self.viewModel.transferAmountDataSource[indexPath.row]
    cell.textLabel?.textAlignment = .right
    cell.backgroundColor = .clear
    cell.textLabel?.textColor = UIColor(named: "textWhiteColor")
    cell.textLabel?.font = UIFont.Kyber.regular(with: 16)
    cell.textLabel?.text = cm
    return cell
  }
}
