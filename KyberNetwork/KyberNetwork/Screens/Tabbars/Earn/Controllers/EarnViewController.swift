//
//  EarnViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/27/21.
//

import UIKit
import BigInt
import TrustCore

class EarnViewModel {
  fileprivate var tokenData: TokenData
  fileprivate var platformDataSource: [EarnSelectTableViewCellViewModel]
  fileprivate(set) var balances: [String: Balance] = [:]
  var isEarnAllBalanace: Bool = false

  fileprivate(set) var balance: Balance?
  fileprivate(set) var amount: String = ""
  
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var wallet: Wallet

  init(data: TokenData, wallet: Wallet) {
    self.tokenData = data
    let dataSource = self.tokenData.lendingPlatforms.map { EarnSelectTableViewCellViewModel(platform: $0) }
    let optimizeValue = dataSource.max { (left, right) -> Bool in
      return left.stableBorrowRate < right.stableBorrowRate
    }
    if let notNilValue = optimizeValue {
      notNilValue.isSelected = true
    }
    self.platformDataSource = dataSource
    self.wallet = wallet
  }
  
  func updateToken(_ token: TokenData) {
    self.tokenData = token
    let dataSource = self.tokenData.lendingPlatforms.map { EarnSelectTableViewCellViewModel(platform: $0) }
    let optimizeValue = dataSource.max { (left, right) -> Bool in
      return left.stableBorrowRate < right.stableBorrowRate
    }
    if let notNilValue = optimizeValue {
      notNilValue.isSelected = true
    }
    self.platformDataSource = dataSource
  }
  
  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.tokenData.address.lowercased()] {
      if let oldBalance = self.balance, oldBalance.value != bal.value { self.isEarnAllBalanace = false }
      self.balance = bal
    }
  }
  
  func resetBalances() {
    self.balances = [:]
  }
  
  var displayBalance: String {
    guard let bal = self.balance else { return "0" }
    let string = bal.value.string(
      decimals: self.tokenData.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.tokenData.decimals, 6)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }

  var totalBalanceText: String {
    return "\(self.displayBalance) \(self.tokenData.symbol)"
  }
  
  func updateAmount(_ amount: String, forSendAllETH: Bool = false) {
    self.amount = amount
    guard !forSendAllETH else {
      return
    }
    self.isEarnAllBalanace = false
  }
  
  var amountBigInt: BigInt {
    return amount.amountBigInt(decimals: self.tokenData.decimals) ?? BigInt(0)
  }

  var isAmountTooSmall: Bool {
    if self.tokenData.symbol == "ETH" { return false }
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    let balanceVal = balance?.value ?? BigInt(0)
    return amountBigInt > balanceVal
  }
  
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }
  
  var allTokenBalanceString: String {
    if self.tokenData.symbol == "ETH" {
      let balance = self.balances[self.tokenData.address.lowercased()]?.value ?? BigInt(0)
      let availableValue = max(BigInt(0), balance - self.allETHBalanceFee)
      let string = availableValue.string(
        decimals: self.tokenData.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.tokenData.decimals, 6)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.displayBalance.removeGroupSeparator()
  }
  
  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) { //TODO: can be improve with enum function
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: return
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
    return "Gas fee: \(feeString) ETH (\(typeString))"
  }
  //TODO: can be improve with extension
  var gasFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }
  
  var selectedPlatform: String {
    let selected = self.platformDataSource.first { $0.isSelected == true }
    return selected?.platform ?? ""
  }

  var minDestQty: BigInt {
    return self.amountBigInt * BigInt(10000.0 - 3 * 100.0) / BigInt(10000.0)
  }
  @discardableResult
  func updateGasLimit(_ value: BigInt, platform: String, tokenAddress: String) -> Bool {
    if self.selectedPlatform == platform && self.tokenData.address == tokenAddress {
      self.gasLimit = value
      return true
    }
    return false
  }
  
  func buildSignSwapTx(dict: [String: String]) -> SignTransaction? {
    guard let dataHexStr = dict["data"],
          let to = dict["to"],
          let valueHexString = dict["value"],
          let value = BigInt(valueHexString.drop0x, radix: 16),
          let gasPriceHexString = dict["gasPrice"],
          let gasPrice = BigInt(gasPriceHexString.drop0x, radix: 16),
          let gasLimitHexString = dict["gasLimit"],
          let gasLimit = BigInt(gasLimitHexString.drop0x, radix: 16),
          let nonceHexStr = dict["nonce"],
          let nonce = Int(nonceHexStr.drop0x, radix: 16)
    else
    {
      return nil
    }
    if case let .real(account) = self.wallet.type {
      return SignTransaction(
        value: value,
        account: account,
        to: Address(string: to),
        nonce: nonce,
        data: Data(hex: dataHexStr.drop0x),
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        chainID: KNEnvironment.default.chainID
      )
    } else {
      //TODO: handle watch wallet type
      return nil
    }
  }
  
  var selectedPlatformData: LendingPlatformData {
    let selected = self.selectedPlatform
    let filtered = self.tokenData.lendingPlatforms.first { (element) -> Bool in
      return element.name == selected
    }
    
    if let wrapped = filtered {
      return wrapped
    } else {
      return self.tokenData.lendingPlatforms.first!
    }
  }
  
  var hintSwapNowText: NSAttributedString {
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let orangeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWYellow,
    ]
    let text  = String(format: "If you don’t have %@, please ".toBeLocalised(), self.tokenData.symbol.uppercased())
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: text, attributes: normalAttributes))
    attributedText.append(NSAttributedString(string: "Swap Now", attributes: orangeAttributes)
    )
    return attributedText
  }
}

enum EarnViewEvent {
  case openGasPriceSelect(gasLimit: BigInt, selectType: KNSelectedGasPriceType, isSwap: Bool, minRatePercent: Double)
  case getGasLimit(lendingPlatform: String, src: String, dest: String, srcAmount: String, minDestAmount: String, gasPrice: String, isSwap: Bool)
  case buildTx(lendingPlatform: String, src: String, dest: String, srcAmount: String, minDestAmount: String, gasPrice: String, isSwap: Bool)
  case confirmTx(fromToken: TokenData, toToken: TokenData, platform: LendingPlatformData, fromAmount: BigInt, toAmount: BigInt, gasPrice: BigInt, gasLimit: BigInt, transaction: SignTransaction, isSwap: Bool)
  case openEarnSwap(token: TokenData, wallet: Wallet)
  case getAllRates(from: TokenData, to: TokenData, srcAmount: BigInt)
  case openChooseRate(from: TokenData, to: TokenData, rates: [JSONDictionary])
  case getRefPrice(from: TokenData, to: TokenData)
  case checkAllowance(token: TokenData)
  case sendApprove(token: TokenData, remain: BigInt)
  case searchToken(isSwap: Bool)
}

protocol EarnViewControllerDelegate: class {
  func earnViewController(_ controller: KNBaseViewController, run event: EarnViewEvent)
}

class EarnViewController: KNBaseViewController {
  @IBOutlet weak var platformTableView: UITableView!
  @IBOutlet weak var fromAmountTextField: UITextField!
  @IBOutlet weak var maxFromAmountButton: UIButton!
  @IBOutlet weak var tokenSelectButton: UIButton!
  @IBOutlet weak var fromBalanceLable: UILabel!
  @IBOutlet weak var hintToNavigateToSwapViewLabel: UILabel!
  @IBOutlet weak var selectedGasFeeLabel: UILabel!
  @IBOutlet weak var platformTableViewHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var compInfoMessageContainerView: UIView!
  @IBOutlet weak var sendButtonTopContraint: NSLayoutConstraint!
  @IBOutlet weak var earnButton: UIButton!
  @IBOutlet weak var selectDepositTitleLabel: UILabel!
  
  let viewModel: EarnViewModel
  fileprivate var isViewSetup: Bool = false
  fileprivate var isViewDisappeared: Bool = false
  weak var delegate: EarnViewControllerDelegate?
  
  init(viewModel: EarnViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: EarnSelectTableViewCell.className, bundle: nil)
    self.platformTableView.register(
      nib,
      forCellReuseIdentifier: EarnSelectTableViewCell.kCellID
    )
    self.platformTableView.rowHeight = EarnSelectTableViewCell.kCellHeight
    
    self.earnButton.setTitle("Next".toBeLocalised(), for: .normal)
    self.earnButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.updateUITokenDidChange(self.viewModel.tokenData)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.earnButton.removeSublayer(at: 0)
    self.earnButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.isViewSetup = true
    self.isViewDisappeared = false
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.updateUIBalanceDidChange()
    
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isViewDisappeared = true
    self.view.endEditing(true)
  }

  func updateUIBalanceDidChange() {
    guard self.isViewSetup else {
      return
    }
    self.fromBalanceLable.text = self.viewModel.totalBalanceText
  }

  fileprivate func updateGasFeeUI() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
  }
  
  fileprivate func updateInforMessageUI() {
    if self.viewModel.selectedPlatform == "Compound" {
      self.compInfoMessageContainerView.isHidden = false
      self.sendButtonTopContraint.constant = 127
    } else {
      self.compInfoMessageContainerView.isHidden = true
      self.sendButtonTopContraint.constant = 30
    }
  }

  @IBAction func gasFeeAreaTapped(_ sender: UIButton) {
    self.delegate?.earnViewController(self, run: .openGasPriceSelect(gasLimit: self.viewModel.gasLimit, selectType: self.viewModel.selectedGasPriceType, isSwap: false, minRatePercent: 0))
  }

  @IBAction func maxAmountButtonTapped(_ sender: UIButton) {
    self.keyboardSendAllButtonPressed(sender)
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    //TODO: validate data before send
    guard !self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) else {
      return
    }
    self.buildTx()
  }
  
  @IBAction func earnSwapMessageLabelTapped(_ sender: UITapGestureRecognizer) {
    self.delegate?.earnViewController(self, run: .openEarnSwap(token: self.viewModel.tokenData, wallet: self.viewModel.wallet))
  }
  
  @IBAction func fromTokenButtonTapped(_ sender: UIButton) {
    self.delegate?.earnViewController(self, run: .searchToken(isSwap: false))
  }
  

  func keyboardSendAllButtonPressed(_ sender: Any) {
    self.viewModel.isEarnAllBalanace = true
    self.fromAmountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", forSendAllETH: self.viewModel.tokenData.symbol == "ETH")
    self.fromAmountTextField.resignFirstResponder()
    self.updateGasLimit()
    
    if sender as? EarnViewController != self {
      if self.viewModel.tokenData.symbol == "ETH" {
        self.showSuccessTopBannerMessage(
          with: "",
          message: NSLocalizedString("a.small.amount.of.eth.is.used.for.transaction.fee", value: "A small amount of ETH will be used for transaction fee", comment: ""),
          time: 1.5
        )
      }
    }
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }

  func updateGasLimit() {
    let event = EarnViewEvent.getGasLimit(
      lendingPlatform: self.viewModel.selectedPlatform,
      src: self.viewModel.tokenData.address,
      dest: self.viewModel.tokenData.address,
      srcAmount: self.viewModel.amountBigInt.description,
      minDestAmount: self.viewModel.minDestQty.description,
      gasPrice: self.viewModel.gasPrice.description,
      isSwap: false
    )
    self.delegate?.earnViewController(self, run: event)
  }
  
  func buildTx() {
    let event = EarnViewEvent.buildTx(
      lendingPlatform: self.viewModel.selectedPlatform,
      src: self.viewModel.tokenData.address,
      dest: self.viewModel.tokenData.address,
      srcAmount: self.viewModel.amountBigInt.description,
      minDestAmount: self.viewModel.minDestQty.description,
      gasPrice: self.viewModel.gasPrice.description,
      isSwap: false
    )
    self.delegate?.earnViewController(self, run: event)
  }
  
  fileprivate func updateUITokenDidChange(_ token: TokenData) {
    self.tokenSelectButton.setTitle(token.symbol.uppercased(), for: .normal)
    self.platformTableViewHeightContraint.constant = CGFloat(self.viewModel.platformDataSource.count) * EarnSelectTableViewCell.kCellHeight
    self.updateInforMessageUI()
    self.platformTableView.reloadData()
    
    self.hintToNavigateToSwapViewLabel.attributedText = self.viewModel.hintSwapNowText
    self.selectDepositTitleLabel.text = String(format: "Select the platform to deposit %@", token.symbol.uppercased())
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.updateUIBalanceDidChange()
  }

  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.resetBalances()
    self.updateUIBalanceDidChange()
  }

  fileprivate func updateAmountFieldUIForTransferAllETHIfNeeded() {
    if self.viewModel.isEarnAllBalanace && self.viewModel.tokenData.symbol == "ETH" {
      self.fromAmountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", forSendAllETH: true)
      self.fromAmountTextField.resignFirstResponder()
    }
  }

  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.updateAmountFieldUIForTransferAllETHIfNeeded()
    self.updateGasFeeUI()
    self.updateGasLimit()
  }

  func coordinatorDidUpdateGasLimit(_ value: BigInt, platform: String, tokenAdress: String) {
    if self.viewModel.updateGasLimit(value, platform: platform, tokenAddress: tokenAdress) {
      self.updateAmountFieldUIForTransferAllETHIfNeeded()
      self.updateGasFeeUI()
    } else {
      self.updateGasLimit()
    }
  }

  func coordinatorFailUpdateGasLimit() {
    self.updateGasLimit()
  }
  
  func coordinatorDidUpdateSuccessTxObject(txObject: [String: String]) {
    guard let tx = self.viewModel.buildSignSwapTx(dict: txObject) else {
      self.navigationController?.showErrorTopBannerMessage(with: "Can not build transaction".toBeLocalised())
      return
    }
    
    let event = EarnViewEvent.confirmTx(fromToken: self.viewModel.tokenData, toToken: self.viewModel.tokenData, platform: self.viewModel.selectedPlatformData, fromAmount: self.viewModel.amountBigInt, toAmount: self.viewModel.amountBigInt, gasPrice: self.viewModel.gasPrice, gasLimit: self.viewModel.gasLimit, transaction: tx, isSwap: false)
    self.delegate?.earnViewController(self, run: event)
  }
  
  func coordinatorFailUpdateTxObject(error: Error) {
    self.navigationController?.showErrorTopBannerMessage(with: error.localizedDescription)
  }
  
  func coordinatorUpdateSelectedToken(_ token: TokenData) {
    self.viewModel.updateToken(token)
    self.updateUITokenDidChange(token)
    self.fromAmountTextField.text = ""
    self.viewModel.updateAmount("")
    self.updateUIBalanceDidChange()
    self.updateGasLimit()
  }
}

extension EarnViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.platformDataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: EarnSelectTableViewCell.kCellID,
      for: indexPath
    ) as! EarnSelectTableViewCell
    let cellViewModel = self.viewModel.platformDataSource[indexPath.row]
    cell.updateCellViewViewModel(cellViewModel)
    return cell
  }
}

extension EarnViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellViewModel = self.viewModel.platformDataSource[indexPath.row]
    self.viewModel.platformDataSource.forEach { (element) in
      element.isSelected = false
    }
    cellViewModel.isSelected = true
    tableView.reloadData()
    self.updateGasLimit()
    self.updateInforMessageUI()
  }
}

extension EarnViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateAmount("")
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let cleanedText = text.cleanStringToNumber()
    if textField == self.fromAmountTextField, cleanedText.amountBigInt(decimals: self.viewModel.tokenData.decimals) == nil { return false }
    textField.text = cleanedText
    self.viewModel.updateAmount(cleanedText)
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.isEarnAllBalanace = false
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    _ = self.showWarningInvalidAmountDataIfNeeded()
    self.updateGasLimit()
  }

  fileprivate func showWarningInvalidAmountDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming && self.isViewDisappeared { return false }
//    if isConfirming {
//      guard self.viewModel.isHavingEnoughETHForFee else {
//        let fee = self.viewModel.ethFeeBigInt
//        self.showWarningTopBannerMessage(
//          with: NSLocalizedString("Insufficient ETH for transaction", value: "Insufficient ETH for transaction", comment: ""),
//          message: String(format: "Deposit more ETH or click Advanced to lower GAS fee".toBeLocalised(), fee.shortString(units: .ether, maxFractionDigits: 6))
//        )
//        return true
//      }
//    }
    //TODO: check fee is vaild
    guard !self.viewModel.amount.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid input", comment: ""),
        message: NSLocalizedString("please.enter.an.amount.to.continue", value: "Please enter an amount to continue", comment: "")
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
}
