//
//  EarnSwapViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/5/21.
//

import UIKit
import BigInt
import TrustCore

class EarnSwapViewModel {
  fileprivate var fromTokenData: TokenData
  fileprivate var toTokenData: TokenData
  fileprivate var platformDataSource: [EarnSelectTableViewCellViewModel]
  fileprivate(set) var balances: [String: Balance] = [:]
  var isSwapAllBalance: Bool = false

  fileprivate(set) var balance: Balance?
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true
  
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var wallet: Wallet
  
  var swapRates: (String, String, BigInt, [JSONDictionary]) = ("", "", BigInt(0), [])
  var currentFlatform: String = "kyber"
  var remainApprovedAmount: (TokenData, BigInt)?
  var latestNonce: Int = -1
  var refPrice: (TokenData, TokenData, String, [String])
  fileprivate(set) var minRatePercent: Double = 3.0

  init(to: TokenData, from: TokenData, wallet: Wallet) {
    self.fromTokenData = from
    self.toTokenData = to
    let dataSource = self.toTokenData.lendingPlatforms.map { EarnSelectTableViewCellViewModel(platform: $0) }
    let optimizeValue = dataSource.max { (left, right) -> Bool in
      return left.stableBorrowRate < right.stableBorrowRate
    }
    if let notNilValue = optimizeValue {
      notNilValue.isSelected = true
    }
    self.platformDataSource = dataSource
    self.wallet = wallet
    
    self.refPrice = (self.fromTokenData, self.toTokenData, "", [])
  }
  
  func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }
  
  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.fromTokenData.address.lowercased()] {
      if let oldBalance = self.balance, oldBalance.value != bal.value { self.isSwapAllBalance = false }
      self.balance = bal
    }
  }
  
  func updateFromToken(_ token: TokenData) {
    self.fromTokenData = token
    if let bal = balances[self.fromTokenData.address.lowercased()] {
      self.balance = bal
    }
  }
  
  func resetBalances() {
    self.balances = [:]
  }
  
  var displayBalance: String {
    guard let bal = self.balance else { return "0" }
    let string = bal.value.string(
      decimals: self.fromTokenData.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.fromTokenData.decimals, 6)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }

  var totalBalanceText: String {
    return "\(self.displayBalance) \(self.fromTokenData.symbol)"
  }
  
  func updateAmount(_ amount: String, isSource: Bool, forSendAllETH: Bool = false) {
    if isSource {
      self.amountFrom = amount
      guard !forSendAllETH else {
        return
      }
      self.isSwapAllBalance = false
    } else {
      self.amountTo = amount
    }
  }
  
  var amountToBigInt: BigInt {
    return amountTo.amountBigInt(decimals: self.toTokenData.decimals) ?? BigInt(0)
  }

  var isAmountTooSmall: Bool {
    if self.fromTokenData.symbol == "ETH" { return false }
    return self.amountFromBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    let balanceVal = balance?.value ?? BigInt(0)
    return self.amountFromBigInt > balanceVal
  }
  
  var amountFromBigInt: BigInt {
    return self.amountFrom.removeGroupSeparator().amountBigInt(decimals: self.fromTokenData.decimals) ?? BigInt(0)
  }
  
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }
  
  var allTokenBalanceString: String {
    if self.fromTokenData.symbol == "ETH" {
      let balance = self.balances[self.fromTokenData.address.lowercased()]?.value ?? BigInt(0)
      let availableValue = max(BigInt(0), balance - self.allETHBalanceFee)
      let string = availableValue.string(
        decimals: self.fromTokenData.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.fromTokenData.decimals, 6)
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
    return self.amountToBigInt * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }
  @discardableResult
  func updateGasLimit(_ value: BigInt, platform: String, tokenAddress: String) -> Bool {
    if self.selectedPlatform == platform && self.toTokenData.address == tokenAddress {
      self.gasLimit = value
      return true
    }
    return false
  }

  func buildSignSwapTx(_ object: TxObject) -> SignTransaction? {
    guard
      let value = BigInt(object.value.drop0x, radix: 16),
      let gasPrice = BigInt(object.gasPrice.drop0x, radix: 16),
      let gasLimit = BigInt(object.gasLimit.drop0x, radix: 16),
      let nonce = Int(object.nonce.drop0x, radix: 16)
    else
    {
      return nil
    }
    if case let .real(account) = self.wallet.type {
      return SignTransaction(
        value: value,
        account: account,
        to: Address(string: object.to),
        nonce: nonce,
        data: Data(hex: object.data.drop0x),
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
    let filtered = self.toTokenData.lendingPlatforms.first { (element) -> Bool in
      return element.name == selected
    }
    
    if let wrapped = filtered {
      return wrapped
    } else {
      return self.toTokenData.lendingPlatforms.first!
    }
  }
  
  func getSwapRate(from: String, to: String, amount: BigInt, platform: String) -> String {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.fromTokenData.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()

    guard from == self.swapRates.0, to == self.swapRates.1, !isAmountChanged else {
      return ""
    }

    let rateDict = self.swapRates.3.first { (element) -> Bool in
      if let platformString = element["platform"] as? String {
        return platformString == platform
      } else {
        return false
      }
    }
    if let rateString = rateDict?["rate"] as? String {
      return rateString
    } else {
      return ""
    }
  }

  func resetSwapRates() {
    self.swapRates = ("", "", BigInt(0), [])
  }
  
  func getCurrentRate() -> BigInt? {
    let rateString: String = self.getSwapRate(from: self.fromTokenData.address.lowercased(), to: self.toTokenData.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    return BigInt(rateString)
  }
  
  var expectedReceivedAmountText: String {
    guard !self.amountFromBigInt.isZero else {
      return ""
    }
    let expectedRate = self.getCurrentRate() ?? BigInt(0)
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return expectedRate * amount * BigInt(10).power(self.toTokenData.decimals) / BigInt(10).power(18) / BigInt(10).power(self.fromTokenData.decimals)
    }()
    return expectedAmount.string(
      decimals: self.toTokenData.decimals,
      minFractionDigits: min(self.toTokenData.decimals, 6),
      maxFractionDigits: min(self.toTokenData.decimals, 6)
    ).removeGroupSeparator()
  }
  
  var expectedExchangeAmountText: String {
    guard !self.amountToBigInt.isZero else {
      return ""
    }
    let rate = self.getCurrentRate() ?? BigInt(0)
    let expectedExchange: BigInt = {
      if rate.isZero { return BigInt(0) }
      let amount = self.amountToBigInt * BigInt(10).power(18) * BigInt(10).power(self.fromTokenData.decimals)
      return amount / rate / BigInt(10).power(self.toTokenData.decimals)
    }()
    return expectedExchange.string(
      decimals: self.fromTokenData.decimals,
      minFractionDigits: self.fromTokenData.decimals,
      maxFractionDigits: self.fromTokenData.decimals
    ).removeGroupSeparator()
  }
  //TODO: buid display usd amount
//  var equivalentUSDAmount: BigInt? {
//    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.to) {
//      return usdRate.rate * self.amountToBigInt / BigInt(10).power(self.to.decimals)
//    }
//    return nil
//  }
//
//  var displayEquivalentUSDAmount: String? {
//    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
//    let value = amount.displayRate(decimals: 18)
//    return "~ $\(value) USD"
//  }
  func updateSwapRates(from: TokenData, to: TokenData, amount: BigInt, rates: [JSONDictionary]) {
    guard from == self.fromTokenData, to == self.toTokenData else {
      return
    }
    self.swapRates = (from.address.lowercased(), to.address.lowercased(), amount, rates)
  }
  
  func reloadBestPlatform() {
    let rates = self.swapRates.3
    if rates.count == 1 {
      let dict = rates.first
      if let platformString = dict?["platform"] as? String {
        self.currentFlatform = platformString
      }
    } else {
      let max = rates.max { (left, right) -> Bool in
        if let leftRate = left["rate"] as? String, let leftBigInt = BigInt(leftRate), let rightRate = right["rate"] as? String, let rightBigInt = BigInt(rightRate) {
          return leftBigInt < rightBigInt
        } else {
          return false
        }
      }
      if let platformString = max?["platform"] as? String {
        self.currentFlatform = platformString
      }
    }
  }
  
  var exchangeRateText: String {
    let rateString: String = self.getSwapRate(from: self.fromTokenData.address.lowercased(), to: self.toTokenData.address.lowercased(), amount: self.amountFromBigInt, platform: self.currentFlatform)
    let rate = BigInt(rateString)
    if let notNilRate = rate {
      return notNilRate.isZero ? "---" : "Rate: 1 \(self.fromTokenData.symbol) = \(notNilRate.displayRate(decimals: 18)) \(self.toTokenData.symbol)"
    } else {
      return "---"
    }
  }
  
  func getRefPrice(from: TokenData, to: TokenData) -> String {
    guard from == self.fromTokenData, to == self.toTokenData else {
      return ""
    }
    return self.refPrice.2
  }
  
  var refPriceDiffText: String {
    let refPrice = self.getRefPrice(from: self.fromTokenData, to: self.toTokenData)
    let price = self.getSwapRate(from: self.fromTokenData.address.description, to: self.toTokenData.address.description, amount: self.amountFromBigInt, platform: self.currentFlatform)
    guard !price.isEmpty, !refPrice.isEmpty, let priceInt = Int(price), let refPriceDouble = Double(refPrice) else {
      return ""
    }

    let priceDouble: Double = Double(priceInt) / pow(10.0, 18.0)
    let change = (priceDouble - refPriceDouble) / refPriceDouble * 100.0
    if change > -5.0 {
      return ""
    } else {
      let displayPercent = "\(change)".prefix(6)
      return "↓ \(displayPercent)%"
    }
  }
  
  func updateRefPrice(from: TokenData, to: TokenData, change: String, source: [String]) {
    guard from == self.fromTokenData, to == self.toTokenData else {
      return
    }
    self.refPrice = (from, to, change, source)
  }
  
  var slippageString: String {
    let doubleStr = String(format: "%.2f", self.minRatePercent)
    return "Slippage: \(doubleStr)%"
  }
  
  var isUseGasToken: Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data[self.wallet.address.description] ?? false
  }
  
  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }
}

class EarnSwapViewController: KNBaseViewController, AbstractEarnViewControler {
  @IBOutlet weak var platformTableView: UITableView!
  @IBOutlet weak var toAmountTextField: UITextField!
  @IBOutlet weak var selectedGasFeeLabel: UILabel!
  @IBOutlet weak var platformTableViewHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var compInfoMessageContainerView: UIView!
  @IBOutlet weak var sendButtonTopContraint: NSLayoutConstraint!
  @IBOutlet weak var earnButton: UIButton!
  @IBOutlet weak var fromTokenButton: UIButton!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var fromAmountTextField: UITextField!
  @IBOutlet weak var equivalentUSDValueLabel: UILabel!
  @IBOutlet weak var exchangeRateLabel: UILabel!
  @IBOutlet weak var rateWarningLabel: UILabel!
  @IBOutlet weak var changeRateButton: UIButton!
  @IBOutlet weak var rateWarningContainerView: UIView!
  
  @IBOutlet weak var walletsSelectButton: UIButton!
  
  @IBOutlet weak var isUseGasTokenIcon: UIImageView!
  @IBOutlet weak var slippageLabel: UILabel!
  @IBOutlet weak var approveButtonLeftPaddingContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonRightPaddingContaint: NSLayoutConstraint!
  @IBOutlet weak var approveButton: UIButton!
  @IBOutlet weak var approveButtonEqualWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var toTokenButton: UIButton!
  @IBOutlet weak var selectDepositTitleLabel: UILabel!
  
  let viewModel: EarnSwapViewModel
  fileprivate var isViewSetup: Bool = false
  fileprivate var isViewDisappeared: Bool = false
  weak var delegate: EarnViewControllerDelegate?
  fileprivate var estRateTimer: Timer?
  fileprivate var estGasLimitTimer: Timer?
  weak var navigationDelegate: NavigationBarDelegate?
  
  init(viewModel: EarnSwapViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnSwapViewController.className, bundle: nil)
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
    self.platformTableViewHeightContraint.constant = CGFloat(self.viewModel.platformDataSource.count) * EarnSelectTableViewCell.kCellHeight
    self.updateInforMessageUI()
    self.earnButton.setTitle("Next".toBeLocalised(), for: .normal)
    self.earnButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.updateGasFeeUI()
    self.approveButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.toTokenButton.setTitle(self.viewModel.toTokenData.symbol.uppercased(), for: .normal)
    self.updateUITokenDidChange(self.viewModel.fromTokenData)
    self.updateUIWalletSelectButton()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.earnButton.removeSublayer(at: 0)
    self.earnButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.approveButton.removeSublayer(at: 0)
    self.approveButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.isViewSetup = true
    self.isViewDisappeared = false
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.updateAllRates()
    self.estRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds30,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.updateAllRates()
      }
    )
    self.updateGasLimit()
    self.estGasLimitTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds60,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.updateGasLimit()
      }
    )
    self.updateRefPrice()
    self.updateAllowance()
    self.updateUIBalanceDidChange()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isViewDisappeared = true
    self.view.endEditing(true)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.estRateTimer?.invalidate()
    self.estRateTimer = nil
    self.estGasLimitTimer?.invalidate()
    self.estGasLimitTimer = nil
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

  func updateGasLimit() {
    let event = EarnViewEvent.getGasLimit(
      lendingPlatform: self.viewModel.selectedPlatform,
      src: self.viewModel.toTokenData.address,
      dest: self.viewModel.toTokenData.address,
      srcAmount: self.viewModel.amountToBigInt.description,
      minDestAmount: self.viewModel.minDestQty.description,
      gasPrice: self.viewModel.gasPrice.description,
      isSwap: true
    )
    self.delegate?.earnViewController(self, run: event)
  }
  
  func buildTx() {
    let event = EarnViewEvent.buildTx(
      lendingPlatform: self.viewModel.selectedPlatform,
      src: self.viewModel.fromTokenData.address,
      dest: self.viewModel.toTokenData.address,
      srcAmount: self.viewModel.amountFromBigInt.description,
      minDestAmount: self.viewModel.minDestQty.description,
      gasPrice: self.viewModel.gasPrice.description,
      isSwap: true
    )
    self.delegate?.earnViewController(self, run: event)
  }
  
  fileprivate func updateRefPrice() {
    self.delegate?.earnViewController(self, run: .getRefPrice(from: self.viewModel.fromTokenData, to: self.viewModel.toTokenData))
  }
  
  fileprivate func updateAmountFieldUIForTransferAllETHIfNeeded() {
    //TODO: uncommemnt after add from field outlet
//    if self.viewModel.isEarnAllBalanace && self.viewModel.tokenData.symbol == "ETH" {
//      self.fromAmountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
//      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", forSendAllETH: true)
//      self.fromAmountTextField.resignFirstResponder()
//    }
  }
  
  fileprivate func updateExchangeRateField() {
    self.exchangeRateLabel.text = self.viewModel.exchangeRateText
  }
  
  fileprivate func updateGasFeeUI() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
  }
  
  fileprivate func updateUIRefPrice() {
    let change = self.viewModel.refPriceDiffText
    self.rateWarningLabel.text = change
    self.rateWarningContainerView.isHidden = change.isEmpty
  }
  
  fileprivate func updateApproveButton() {
    self.approveButton.setTitle("Approve".toBeLocalised() + " " + self.viewModel.fromTokenData.symbol, for: .normal)
  }

  fileprivate func updateUIWalletSelectButton() {
    self.walletsSelectButton.setTitle(self.viewModel.wallet.address.description, for: .normal)
  }

  fileprivate func updateUIForSendApprove(isShowApproveButton: Bool) {
    self.updateApproveButton()
    if isShowApproveButton {
      self.approveButtonLeftPaddingContraint.constant = 37
      self.approveButtonRightPaddingContaint.constant = 15
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 1000)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.earnButton.isEnabled = false
      self.earnButton.alpha = 0.2
    } else {
      self.approveButtonLeftPaddingContraint.constant = 0
      self.approveButtonRightPaddingContaint.constant = 37
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 1000)
      self.earnButton.isEnabled = true
      self.earnButton.alpha = 1
    }
    
    self.earnButton.removeSublayer(at: 0)
    self.earnButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.earnButton.removeSublayer(at: 0)
    self.earnButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    
    self.view.layoutIfNeeded()
  }
  
  fileprivate func setUpChangeRateButton() {
    if self.viewModel.currentFlatform == "uniswap" {
      let icon = UIImage(named: "uni_icon_medium")?.resizeImage(to: CGSize(width: 16, height: 16))
      self.changeRateButton.setImage(icon, for: .normal)
    } else {
      let icon = UIImage(named: "kyber_icon_medium")?.resizeImage(to: CGSize(width: 16, height: 16))
      self.changeRateButton.setImage(icon, for: .normal)
    }
  }
  
  fileprivate func setUpGasFeeView() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
    self.slippageLabel.text = self.viewModel.slippageString
    self.isUseGasTokenIcon.isHidden = !self.viewModel.isUseGasToken
  }
  
  fileprivate func updateAllowance() {
    self.delegate?.earnViewController(self, run: .checkAllowance(token: self.viewModel.fromTokenData))
  }
  
  @IBAction func gasFeeAreaTapped(_ sender: UIButton) {
    self.delegate?.earnViewController(self, run: .openGasPriceSelect(gasLimit: self.viewModel.gasLimit, selectType: self.viewModel.selectedGasPriceType, isSwap: true, minRatePercent: self.viewModel.minRatePercent))
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func changeRateButtonTapped(_ sender: UIButton) {
    let rates = self.viewModel.swapRates.3
    if rates.count >= 2 {
      self.delegate?.earnViewController(self, run: .openChooseRate(from: self.viewModel.fromTokenData, to: self.viewModel.toTokenData, rates: rates))
    }
  }
  
  @IBAction func maxAmountButtonTapped(_ sender: UIButton) {
    self.balanceLabelTapped(sender)
  }

  @IBAction func approveButtonTapped(_ sender: UIButton) {
    guard let remain = self.viewModel.remainApprovedAmount else {
      return
    }
    self.delegate?.earnViewController(self, run: .sendApprove(token: remain.0, remain: remain.1))
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    guard !self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) else {
      return
    }
    self.buildTx()
  }
  
  @IBAction func fromTokenButtonTapped(_ sender: UIButton) {
    self.delegate?.earnViewController(self, run: .searchToken(isSwap: true))
  }
  
  @objc func balanceLabelTapped(_ sender: Any) {
    self.keyboardSwapAllButtonPressed(sender)
  }
  
  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }
  
  @IBAction func walletsButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }
  
  func keyboardSwapAllButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "kbswap_swap_all", customAttributes: nil)
    self.view.endEditing(true)
    self.viewModel.updateFocusingField(true)
    self.fromAmountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true, forSendAllETH: self.viewModel.fromTokenData.isETH)
//    self.updateTokensView()
    self.updateViewAmountDidChange()
    self.updateAllRates()
    if sender as? KSwapViewController != self {
      if self.viewModel.fromTokenData.isETH {
        self.showSuccessTopBannerMessage(
          with: "",
          message: NSLocalizedString("a.small.amount.of.eth.is.used.for.transaction.fee", value: "A small amount of ETH will be used for transaction fee", comment: ""),
          time: 1.5
        )
      }
    }

    self.viewModel.isSwapAllBalance = true
    self.view.layoutIfNeeded()
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
  
  func coordinatorDidUpdateSuccessTxObject(txObject: TxObject) {
    guard let tx = self.viewModel.buildSignSwapTx(txObject) else {
      self.navigationController?.showErrorTopBannerMessage(with: "Can not build transaction".toBeLocalised())
      return
    }

    let event = EarnViewEvent.confirmTx(
      fromToken: self.viewModel.fromTokenData,
      toToken: self.viewModel.toTokenData,
      platform: self.viewModel.selectedPlatformData,
      fromAmount: self.viewModel.amountFromBigInt,
      toAmount: self.viewModel.amountToBigInt,
      gasPrice: self.viewModel.gasPrice,
      gasLimit: self.viewModel.gasLimit,
      transaction: tx,
      isSwap: true,
      rawTransaction: txObject
    )
    self.delegate?.earnViewController(self, run: event)
  }
  
  func coordinatorFailUpdateTxObject(error: Error) {
    self.navigationController?.showErrorTopBannerMessage(with: error.localizedDescription)
  }
  
  func coordinatorDidUpdateRates(from: TokenData, to: TokenData, srcAmount: BigInt, rates: [JSONDictionary]) {
    self.viewModel.updateSwapRates(from: from, to: to, amount: srcAmount, rates: rates)
    self.viewModel.reloadBestPlatform()
    self.updateExchangeRateField()
    self.setUpChangeRateButton()
    self.updateUIRefPrice()
    self.updateInputFieldsUI()
  }

  func coordinatorFailUpdateRates() {
    //TODO: show error loading rate if needed on UI
  }
  
  func coordinatorDidUpdatePlatform(_ platform: String) {
    self.viewModel.currentFlatform = platform
    self.setUpChangeRateButton()
  }
  
  func coordinatorSuccessUpdateRefPrice(from: TokenData, to: TokenData, change: String, source: [String]) {
    self.viewModel.updateRefPrice(from: from, to: to, change: change, source: source)
    self.updateUIRefPrice()
  }
  
  func coordinatorDidUpdateMinRatePercentage(_ value: CGFloat) {
    self.viewModel.updateExchangeMinRatePercent(Double(value))
    self.setUpGasFeeView()
  }
  
  fileprivate func updateGasTokenArea() {
    self.isUseGasTokenIcon.isHidden = !self.viewModel.isUseGasToken
  }
  
  func updateUIBalanceDidChange() {
    guard self.isViewSetup else {
      return
    }
    self.balanceLabel.text = self.viewModel.totalBalanceText
  }
  
  fileprivate func updateUITokenDidChange(_ token: TokenData) {
    self.fromTokenButton.setTitle(token.symbol.uppercased(), for: .normal)
    self.selectDepositTitleLabel.text = String(format: "Select the platform to deposit %@", token.symbol.uppercased())
  }
  
  func coordinatorUpdateIsUseGasToken(_ state: Bool) {
    self.updateGasTokenArea()
  }
  
  func coordinatorDidUpdateAllowance(token: TokenData, allowance: BigInt) {
    guard let balanceValue = self.viewModel.balance else {
      return
    }
    if balanceValue.value > allowance {
      self.viewModel.remainApprovedAmount = (token, allowance)
      self.updateUIForSendApprove(isShowApproveButton: true)
    } else {
      self.updateUIForSendApprove(isShowApproveButton: false)
    }
  }

  func coordinatorDidFailUpdateAllowance(token: TokenData) {
    //TODO: handle error
  }
  
  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.updateUIBalanceDidChange()
  }
  
  func coordinatorSuccessApprove(token: TokenObject) {
    self.updateUIForSendApprove(isShowApproveButton: false)
  }

  func coordinatorFailApprove(token: TokenObject) {
    self.showErrorMessage()
    self.updateUIForSendApprove(isShowApproveButton: true)
  }
  
  fileprivate func showErrorMessage() {
    self.showWarningTopBannerMessage(
      with: "",
      message: "Something went wrong, please try again later".toBeLocalised(),
      time: 2.0
    )
  }

  func coordinatorUpdateSelectedToken(_ token: TokenData) {
    self.viewModel.updateFromToken(token)
    self.updateUITokenDidChange(token)
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    if self.viewModel.fromTokenData == self.viewModel.toTokenData {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: NSLocalizedString("can.not.swap.same.token", value: "Can not swap the same token", comment: ""),
        time: 1.5
      )
    }
    self.updateUIBalanceDidChange()
    self.updateApproveButton()
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.updateGasLimit()
    self.updateAllowance()
    self.updateAllRates()
  }
}

extension EarnSwapViewController: UITableViewDataSource {
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

extension EarnSwapViewController: UITableViewDelegate {
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

extension EarnSwapViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.viewModel.updateAmount("", isSource: textField != self.toAmountTextField)
    self.viewModel.isSwapAllBalance = false
    self.updateViewAmountDidChange()
    self.updateAllRates()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let cleanedText = text.cleanStringToNumber()
    if textField == self.fromAmountTextField && cleanedText.amountBigInt(decimals: self.viewModel.fromTokenData.decimals) == nil { return false }
    if textField == self.toAmountTextField && cleanedText.amountBigInt(decimals: self.viewModel.toTokenData.decimals) == nil { return false }
    let double: Double = {
      if textField == self.fromAmountTextField {
        let bigInt = Double(text.amountBigInt(decimals: self.viewModel.fromTokenData.decimals) ?? BigInt(0))
        return Double(bigInt) / pow(10.0, Double(self.viewModel.fromTokenData.decimals))
      }
      let bigInt = Double(text.amountBigInt(decimals: self.viewModel.toTokenData.decimals) ?? BigInt(0))
      return Double(bigInt) / pow(10.0, Double(self.viewModel.toTokenData.decimals))
    }()
    textField.text = text
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.viewModel.updateAmount(text, isSource: textField == self.fromAmountTextField)
    self.updateAllRates()
    self.updateViewAmountDidChange()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.isSwapAllBalance = false
    self.viewModel.updateFocusingField(textField == self.fromAmountTextField)
    self.updateViewAmountDidChange()
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    _ = self.showWarningInvalidAmountDataIfNeeded()
    self.updateGasLimit()
    self.updateAllRates()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = self.showWarningInvalidAmountDataIfNeeded()
    }
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
    guard !self.viewModel.amountTo.isEmpty else {
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

  fileprivate func updateViewAmountDidChange() {
    self.updateInputFieldsUI()
    self.updateExchangeRateField()
  }
  
  fileprivate func updateInputFieldsUI() {
    if self.viewModel.isFocusingFromAmount {
      self.toAmountTextField.text = self.viewModel.expectedReceivedAmountText
      self.viewModel.updateAmount(self.toAmountTextField.text ?? "", isSource: false)
    } else {
      self.fromAmountTextField.text = self.viewModel.expectedExchangeAmountText
      self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    }
  }
  
  fileprivate func updateAllRates() {
    let event = EarnViewEvent.getAllRates(from: self.viewModel.fromTokenData, to: self.viewModel.toTokenData, srcAmount: self.viewModel.amountFromBigInt)
    self.delegate?.earnViewController(self, run: event)
  }
}
