//
//  WithdrawViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/2/21.
//

import UIKit
import BigInt
import KrystalWallets
import Utilities
import BaseModule

class WithdrawViewModel {
  let platform: String
  let balance: LendingBalance
  var withdrawableAmountBigInt: BigInt
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  var amount: String = ""
  var isBearingTokenApproved: Bool = true
  var isUseGasToken: Bool = false
  var approvingTokenAddress: String?
  var toAddress: String = ""
  var remainApproveAmt: BigInt = BigInt(0)
  
  var address: KAddress {
    return AppDelegate.session.address
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

  init(platform: String, balance: LendingBalance) {
    self.platform = platform
    self.balance = balance
    self.withdrawableAmountBigInt = BigInt(balance.supplyBalance) ?? BigInt(0)
  }
  
  var amountBigInt: BigInt {
    return self.amount.amountBigInt(decimals: self.balance.decimals) ?? BigInt(0)
  }
  
  var displayAmount: String {
    return self.amountBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: 5)
  }
  
  var withdrawableAmountString: String {
    return self.withdrawableAmountBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: self.balance.decimals)
  }
  
  var isAmountTooSmall: Bool {
    if self.balance.symbol == "ETH" { return false }
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    return self.amountBigInt > self.withdrawableAmountBigInt
  }
  
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }
  
  var isEnoughFee: Bool {
    let ethBalance = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return ethBalance > self.transactionFee
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
  
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee = gasPrice * self.gasLimit
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
    default:
      break
    }
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken) (\(typeString))"
  }

  var gasFeeString: String {
    self.updateSelectedGasPriceType(self.selectedGasPriceType)
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }

  var displayTitle: String {
    return "Withdraw".toBeLocalised() + " " + self.balance.symbol.uppercased()
  }
  
  var transactionFee: BigInt {
    return self.gasPrice * self.gasLimit
  }

  var feeETHString: String {
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) \(KNGeneralProvider.shared.quoteToken)"
  }
  
  var feeUSDString: String {
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.transactionFee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }
  
  var displayWithdrawableAmount: String {
    return self.withdrawableAmountBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: self.balance.decimals) + " " + self.balance.symbol.uppercased()
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
    
    func buildExtraInfo() -> WithdrawExtraData {
        return WithdrawExtraData(token: balance.symbol, tokenAmount: "\(balance.supplyBalance)")
    }
}

enum WithdrawViewEvent {
  case getWithdrawableAmount(platform: String, userAddress: String, tokenAddress: String)
  case buildWithdrawTx(platform: String, token: String, amount: String, gasPrice: String, useGasToken: Bool, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxGas: String?, advancedNonce: String?, historyTransaction: InternalHistoryTransaction)
  case updateGasLimit(platform: String, token: String, amount: String, gasPrice: String, useGasToken: Bool)
  case checkAllowance(tokenAddress: String, toAddress: String)
  case sendApprove(tokenAddress: String, remain: BigInt, symbol: String, toAddress: String)
  case openGasPriceSelect(gasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?)
}

protocol WithdrawViewControllerDelegate: class {
  func withdrawViewController(_ controller: WithdrawViewController, run event: WithdrawViewEvent)
}

class WithdrawViewController: InAppBrowsingViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var amountFIeld: UITextField!
  @IBOutlet weak var ethFeeLabel: UILabel!
  @IBOutlet weak var usdFeeLabel: UILabel!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var withdrawButton: UIButton!
  @IBOutlet weak var withdrawableAmountLabel: UILabel!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var transactionGasPriceLabel: UILabel!
  var keyboardTimer: Timer?

  let transitor = TransitionDelegate()
  let viewModel: WithdrawViewModel
  weak var delegate: WithdrawViewControllerDelegate?

  init(viewModel: WithdrawViewModel) {
    self.viewModel = viewModel
    super.init(nibName: WithdrawViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.loadWithdrawableAmount()

    if self.viewModel.balance.requiresApproval {
      self.updateGasLimit()
    }
    self.setupUI()
    self.amountFIeld.setupCustomDeleteIcon()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.updateUIforWithdrawButton()
    self.updateUIWithdrawableAmount()
    self.updateUIFee()
  }

  fileprivate func updateUIFee() {
    self.ethFeeLabel.text = self.viewModel.feeETHString
    self.usdFeeLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
  }

  fileprivate func updateUIWithdrawableAmount() {
    self.withdrawableAmountLabel.text = self.viewModel.displayWithdrawableAmount
  }

  fileprivate func setupUI() {
    self.titleLabel.text = self.viewModel.displayTitle
    self.updateUIFee()
    self.updateUIWithdrawableAmount()
    self.tokenButton.setTitle(self.viewModel.balance.symbol.uppercased(), for: .normal)
    self.withdrawButton.rounded(radius: 16)
    self.updateUIforWithdrawButton()
    self.cancelButton.rounded(radius: 16)
  }

  fileprivate func loadWithdrawableAmount() {
    self.delegate?.withdrawViewController(self, run: .getWithdrawableAmount(platform: self.viewModel.platform, userAddress: self.viewModel.address.addressString, tokenAddress: self.viewModel.balance.address))
  }

  fileprivate func buildTx() {
    let description = "\(self.viewModel.displayAmount) \(self.viewModel.balance.interestBearingTokenSymbol) -> \(self.viewModel.displayAmount) \(self.viewModel.balance.symbol)"
    let historyTransaction = InternalHistoryTransaction(
      type: .withdraw,
      state: .pending,
      fromSymbol: self.viewModel.balance.symbol,
      toSymbol: self.viewModel.balance.interestBearingTokenSymbol,
      transactionDescription: description, transactionDetailDescription: "",
      transactionObj: SignTransactionObject(
        value: "",
        from: "",
        to: "",
        nonce: 0,
        data: Data(),
        gasPrice: "",
        gasLimit: "",
        chainID: 0,
        reservedGasLimit: ""
      ),
      eip1559Tx: nil
    )
    historyTransaction.transactionSuccessDescription = "\(self.viewModel.displayAmount) \(self.viewModel.balance.symbol)"
    
    self.delegate?.withdrawViewController(
      self,
      run: .buildWithdrawTx(
        platform: self.viewModel.platform,
        token: self.viewModel.balance.address,
        amount: self.viewModel.amountBigInt.description,
        gasPrice: self.viewModel.gasPrice.description,
        useGasToken: true,
        advancedGasLimit: self.viewModel.advancedGasLimit,
        advancedPriorityFee: self.viewModel.advancedMaxPriorityFee,
        advancedMaxGas: self.viewModel.advancedMaxFee,
        advancedNonce: self.viewModel.advancedNonce,
        historyTransaction: historyTransaction
      )
    )
  }

  fileprivate func loadAllowance() {
    self.delegate?.withdrawViewController(self, run: .checkAllowance(tokenAddress: self.viewModel.balance.interestBearingTokenAddress, toAddress: self.viewModel.toAddress))
  }

  fileprivate func sendApprove() {
    guard !self.viewModel.toAddress.isEmpty else {
      self.updateGasLimit()
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        self.sendApprove()
      }
      return
    }
    self.delegate?.withdrawViewController(self, run: .sendApprove(
      tokenAddress: self.viewModel.balance.interestBearingTokenAddress.lowercased(),
      remain: self.viewModel.remainApproveAmt,
      symbol: self.viewModel.balance.interestBearingTokenSymbol,
      toAddress: self.viewModel.toAddress
    ))
  }

  fileprivate func updateUIforWithdrawButton() {
    guard self.isViewLoaded, self.viewModel.balance.requiresApproval else {
      return
    }
    if self.viewModel.isBearingTokenApproved {
      self.withdrawButton.setTitle("Withdraw".toBeLocalised(), for: .normal)
      self.withdrawButton.isEnabled = true
      self.withdrawButton.alpha = 1
    } else {
      self.withdrawButton.setTitle("Approve".toBeLocalised() + " " + self.viewModel.balance.interestBearingTokenSymbol.uppercased(), for: .normal)
      if self.viewModel.approvingTokenAddress == nil {
        self.withdrawButton.isEnabled = true
        self.withdrawButton.alpha = 1
      } else {
        self.withdrawButton.isEnabled = false
        self.withdrawButton.alpha = 0.2
      }
    }
  }

  fileprivate func updateGasLimit() {
    self.delegate?.withdrawViewController(self, run: .updateGasLimit(platform: self.viewModel.platform, token: self.viewModel.balance.address, amount: self.viewModel.amountBigInt.description, gasPrice: self.viewModel.gasPrice.description, useGasToken: true))
  }
  
  func coordinatorDidUpdateWithdrawableAmount(_ amount: String) {
    self.viewModel.withdrawableAmountBigInt = BigInt(amount) ?? BigInt(0)
    self.updateUIforWithdrawButton()
  }

  func coodinatorFailUpdateWithdrawableAmount() {
    self.loadWithdrawableAmount()
  }
  
  func coordinatorDidUpdateGasLimit(value: BigInt, toAddress: String) {
    let previous = self.viewModel.toAddress
    self.viewModel.gasLimit = value
    self.viewModel.toAddress = toAddress
    if self.viewModel.balance.requiresApproval, previous.isEmpty {
      self.loadAllowance()
    }
    self.updateUIFee()
  }
  
  func coordinatorFailUpdateGasLimit() {
    self.updateGasLimit()
  }
  
  func coordinatorDidUpdateAllowance(token: String, allowance: BigInt) {
    if allowance.isZero || allowance < self.viewModel.withdrawableAmountBigInt {
      self.viewModel.isBearingTokenApproved = false
    } else {
      self.viewModel.isBearingTokenApproved = true
    }
    self.viewModel.remainApproveAmt = allowance
    self.updateUIforWithdrawButton()
  }

  func coordinatorDidFailUpdateAllowance(token: String) {
    self.loadAllowance()
  }

  func coordinatorSuccessApprove(token: String) {
    self.viewModel.approvingTokenAddress = token
    self.viewModel.isBearingTokenApproved = false
    self.updateUIforWithdrawButton()
  }

  func coordinatorFailApprove(token: String) {
    self.showErrorMessage()
    self.viewModel.isBearingTokenApproved = false
    self.updateUIforWithdrawButton()
  }

  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.updateUIFee()
    self.updateGasLimit()
    self.viewModel.resetAdvancedSettings()
  }

  fileprivate func showErrorMessage() {
    self.showWarningTopBannerMessage(
      with: "",
      message: "Something went wrong, please try again later".toBeLocalised(),
      time: 2.0
    )
  }

  func coordinatorUpdateIsUseGasToken(_ status: Bool) {
    self.viewModel.isUseGasToken = status
  }

  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.updateSelectedGasPriceType(.custom)
    self.updateUIFee()
  }

  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }

  func coordinatorSuccessSendTransaction() {
    self.viewModel.advancedGasLimit = nil
    self.viewModel.advancedMaxPriorityFee = nil
    self.viewModel.advancedMaxFee = nil
    self.viewModel.updateSelectedGasPriceType(.medium)
    self.updateUIFee()
    self.viewModel.resetAdvancedSettings()
  }

  @IBAction func withdrawButtonTapped(_ sender: UIButton) {
    if self.viewModel.isBearingTokenApproved {
      guard !self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) else { return }
      self.buildTx()
      MixPanelManager.track("earn_withdraw", properties: ["screenid": "earn_withdraw_pop_up"])
    } else {
      self.sendApprove()
    }
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func selectGasPriceButtonTapped(_ sender: Any) {
    self.delegate?.withdrawViewController(self, run: .openGasPriceSelect(
      gasLimit: self.viewModel.gasLimit,
      selectType: self.viewModel.selectedGasPriceType,
      advancedGasLimit: self.viewModel.advancedGasLimit,
      advancedPriorityFee: self.viewModel.advancedMaxPriorityFee,
      advancedMaxFee: self.viewModel.advancedMaxFee,
      advancedNonce: self.viewModel.advancedNonce
    ))
  }
  
  @IBAction func maxButtonTapped(_ sender: UIButton) {
    self.viewModel.amount = self.viewModel.withdrawableAmountString
    self.amountFIeld.text = self.viewModel.withdrawableAmountString
    self.updateGasLimit()
    MixPanelManager.track("enter_withdraw_amount", properties: ["screenid": "earn_withdraw_pop_up", "withdraw_amount": viewModel.amount, "withdraw_token": viewModel.balance.symbol])
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    self.amountFIeld.resignFirstResponder()
  }
  
  
  func coordinatorDidUpdatePendingTx() {
    self.checkUpdateApproveButton()
  }
  
  fileprivate func checkUpdateApproveButton() {
    guard let tokenAddress = self.viewModel.approvingTokenAddress else {
      return
    }
    if EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty {
      self.viewModel.isBearingTokenApproved = true
      self.viewModel.approvingTokenAddress = nil
      self.updateUIforWithdrawButton()
      
    }
    let pending = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().filter({ (item) -> Bool in
      return item.transactionDetailDescription.lowercased() == tokenAddress.lowercased() && item.type == .allowance
    })
    if pending.isEmpty {
      self.viewModel.isBearingTokenApproved = true
      self.viewModel.approvingTokenAddress = nil
      self.updateUIforWithdrawButton()
    }
  }
}

extension WithdrawViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 470
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension WithdrawViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.amount = ""
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let cleanedText = text.cleanStringToNumber()
    if textField == self.amountFIeld, cleanedText.amountBigInt(decimals: self.viewModel.balance.decimals) == nil { return false }
    textField.text = cleanedText
    self.viewModel.amount = cleanedText
    self.keyboardTimer?.invalidate()
    self.keyboardTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(WithdrawViewController.keyboardPauseTyping),
            userInfo: ["textField": textField],
            repeats: false)
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    _ = self.showWarningInvalidAmountDataIfNeeded()
    self.updateGasLimit()
    MixPanelManager.track("enter_withdraw_amount", properties: ["screenid": "earn_withdraw_pop_up", "withdraw_amount": viewModel.amount, "withdraw_token": viewModel.balance.symbol])
  }

  fileprivate func showWarningInvalidAmountDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming { return false }
    guard !self.viewModel.amount.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid input", comment: ""),
        message: NSLocalizedString("please.enter.an.amount.to.continue", value: "Please enter an amount to continue", comment: "")
      )
      return true
    }
    guard self.viewModel.isEnoughFee else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", value: "Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", comment: ""),
        message: String(format: "Deposit more \(KNGeneralProvider.shared.quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), self.viewModel.transactionFee.shortString(units: .ether, maxFractionDigits: 6))
      )
      return true
    }

    guard !self.viewModel.isAmountTooSmall else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: NSLocalizedString("amount.to.send.greater.than.zero", value: "Amount to transfer should be greater than zero", comment: "")
      )
      return true
    }
    guard !self.viewModel.isAmountTooBig else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: NSLocalizedString("balance.not.enough.to.make.transaction", value: "Balance is not be enough to make the transaction.", comment: "")
      )
      return true
    }
    return false
  }
  
  @objc func keyboardPauseTyping(timer: Timer) {
    self.updateGasLimit()
  }
}
