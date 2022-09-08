//
//  EarnViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/27/21.
//

import UIKit
import BigInt
import KrystalWallets

class EarnViewModel {
  fileprivate var tokenData: TokenData
  fileprivate var platformDataSource: [EarnSelectTableViewCellViewModel]
  var isEarnAllBalanace: Bool = false

  fileprivate(set) var amount: String = ""
  
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var baseGasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
//  fileprivate(set) var wallet: Wallet
  var remainApprovedAmount: (TokenData, BigInt)?
  var approvingToken: TokenObject?
  
  var currentAddress: KAddress {
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

  init(data: TokenData) {
    self.tokenData = data
    let dataSource = self.tokenData.lendingPlatforms.map { EarnSelectTableViewCellViewModel(platform: $0) }
    let optimizeValue = dataSource.max { (left, right) -> Bool in
      return left.supplyRate < right.supplyRate
    }
    if let notNilValue = optimizeValue {
      notNilValue.isSelected = true
    }
    self.platformDataSource = dataSource
//    self.wallet = wallet
  }
  
  func updateToken(_ token: TokenData) {
    self.tokenData = token
    let dataSource = self.tokenData.lendingPlatforms.map { EarnSelectTableViewCellViewModel(platform: $0) }
    let optimizeValue = dataSource.max { (left, right) -> Bool in
      return left.supplyRate < right.supplyRate
    }
    if let notNilValue = optimizeValue {
      notNilValue.isSelected = true
    }
    self.platformDataSource = dataSource
  }
  
  func updateBalance(_ balances: [String: Balance]) {
    
  }
  
  func resetBalances() {
    
  }
  
  var displayBalance: String {
    let string = self.tokenData.getBalanceBigInt().string(
      decimals: self.tokenData.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.tokenData.decimals, 5)
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
    let balanceVal = self.tokenData.getBalanceBigInt()
    return amountBigInt > balanceVal
  }
  
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }
  
  var allTokenBalanceString: String {
    if self.tokenData.isQuoteToken {
      let balance = self.tokenData.getBalanceBigInt()
      let availableValue = max(BigInt(0), balance - self.allETHBalanceFee)
      let string = availableValue.string(
        decimals: self.tokenData.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.tokenData.decimals, 5)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.displayBalance.removeGroupSeparator()
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
    self.gasLimit = self.baseGasLimit
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
    case .custom:
      typeString = "custom".toBeLocalised().uppercased()
    }
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken) (\(typeString))"
  }
  //TODO: can be improve with extension
  var gasFeeString: String {
    self.updateSelectedGasPriceType(self.selectedGasPriceType)
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }
  
  var selectedPlatform: String {
    let selected = self.platformDataSource.first { $0.isSelected == true }
    return selected?.platform ?? ""
  }
  
  var isCompound: Bool {
    return self.selectedPlatform == "Compound" || KNGeneralProvider.shared.currentChain == .bsc
  }

  var minDestQty: BigInt {
    return self.amountBigInt
  }
  @discardableResult
  func updateGasLimit(_ value: BigInt, platform: String, tokenAddress: String) -> Bool {
    if self.selectedPlatform == platform && self.tokenData.address == tokenAddress {
      if self.selectedGasPriceType == .custom {
        self.baseGasLimit = value
      } else {
        self.gasLimit = value
        self.baseGasLimit = value
      }
      
      return true
    }
    return false
  }
  
  func buildSignSwapTx(_ object: TxObject) -> SignTransaction? {
    guard !KNGeneralProvider.shared.isUseEIP1559 else {
      return nil
    }
    guard
      let value = BigInt(object.value.drop0x, radix: 16),
      var gasPrice = BigInt(object.gasPrice.drop0x, radix: 16),
      var gasLimit = BigInt(object.gasLimit.drop0x, radix: 16),
      var nonce = Int(object.nonce.drop0x, radix: 16)
    else
    {
      return nil
    }
    
    if let unwrap = self.advancedMaxFee, let value = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      gasPrice = value
    }
    
    if let unwrap = self.advancedGasLimit, let value = BigInt(unwrap) {
      gasLimit = value
    }
    
    if let unwrap = self.advancedNonce, let value = Int(unwrap) {
      nonce = value
    }
    
    if currentAddress.isWatchWallet {
      return nil
    } else {
      return SignTransaction(
        value: value,
        address: currentAddress.addressString,
        to: object.to,
        nonce: nonce,
        data: Data(hex: object.data.drop0x),
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        chainID: KNGeneralProvider.shared.customRPC.chainID
      )
    }
  }
  
  func buildEIP1559Tx(_ object: TxObject) -> EIP1559Transaction? {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return nil
    }
    let gasLimitDefault = BigInt(object.gasLimit.drop0x, radix: 16) ?? self.gasLimit
    let gasPrice = BigInt(object.gasPrice.drop0x, radix: 16) ?? self.gasPrice
    let baseFeeBigInt = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let priorityFeeBigIntDefault = selectedPriorityFee
    let maxGasFeeDefault = gasPrice
    let chainID = BigInt(KNGeneralProvider.shared.customRPC.chainID).hexEncoded
    var nonce = object.nonce.hexSigned2Complement
    if let customNonceString = self.advancedNonce, let nonceInt = Int(customNonceString) {
      let nonceBigInt = BigInt(nonceInt)
      nonce = nonceBigInt.hexEncoded.hexSigned2Complement
    }
    if let advancedGasStr = self.advancedGasLimit,
       let gasLimit = BigInt(advancedGasStr),
       let priorityFeeString = self.advancedMaxPriorityFee,
       let priorityFee = priorityFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit),
       let maxGasFeeString = self.advancedMaxFee,
       let maxGasFee = maxGasFeeString.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFee.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFee.hexEncoded.hexSigned2Complement,
        toAddress: object.to,
        fromAddress: object.from,
        data: object.data,
        value: object.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
    } else {
      return EIP1559Transaction(
        chainID: chainID.hexSigned2Complement,
        nonce: nonce,
        gasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement,
        maxInclusionFeePerGas: priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
        maxGasFee: maxGasFeeDefault.hexEncoded.hexSigned2Complement,
        toAddress: object.to,
        fromAddress: object.from,
        data: object.data,
        value: object.value.drop0x.hexSigned2Complement,
        reservedGasLimit: gasLimitDefault.hexEncoded.hexSigned2Complement
      )
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
    let normalAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 14),
      NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor"),
    ]
    let orangeAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 14),
      NSAttributedString.Key.foregroundColor: UIColor(named: "buttonBackgroundColor"),
    ]
    let text  = String(format: "If you don’t have %@, please ".toBeLocalised(), self.tokenData.symbol.uppercased())
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: text, attributes: normalAttributes))
    attributedText.append(NSAttributedString(string: "Swap Now", attributes: orangeAttributes)
    )
    return attributedText
  }

  var isUseGasToken: Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data[self.currentAddress.addressString] ?? false
  }
  
  var displayCompInfo: String {
    let comp = self.tokenData.lendingPlatforms.first { item -> Bool in
      return item.isCompound
    }
    let symbol = KNGeneralProvider.shared.compoundSymbol
    let apy = String(format: "%.2f", (comp?.distributionSupplyRate ?? 0.03) * 100.0)
    return "You will automatically earn \(symbol) token (\(apy)% APY) for interacting with \(comp?.name ?? "") (supply or borrow).\nOnce redeemed, \(symbol) token can be swapped to any token."
  }
  
  var gasFeeBigInt: BigInt {
    let fee = self.gasPrice * self.gasLimit
    return fee
  }
  
  var isHavingEnoughETHForFee: Bool {
    var fee = self.gasPrice * self.gasLimit
    if self.tokenData.isETH || self.tokenData.isBNB { fee += self.amountBigInt }
    let ethBal = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    return ethBal >= fee
  }
  
  var displayEstGas: String {
    guard KNGeneralProvider.shared.isUseEIP1559 else {
      return ""
    }
    let baseFee = KNGasCoordinator.shared.baseFee ?? BigInt(0)
    let fee = (baseFee + self.selectedPriorityFee) * self.gasLimit
    let sourceToken = KNGeneralProvider.shared.quoteToken
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(sourceToken) "
  }
  
  var selectedPriorityFee: BigInt {
    switch self.selectedGasPriceType {
    case .slow:
      return KNGasCoordinator.shared.lowPriorityFee ?? BigInt(0)
    case .medium:
      return KNGasCoordinator.shared.standardPriorityFee ?? BigInt(0)
    case .fast:
      return KNGasCoordinator.shared.fastPriorityFee ?? BigInt(0)
    case .superFast:
      return KNGasCoordinator.shared.superFastPriorityFee ?? BigInt(0)
    case .custom:
      if let unwrap = self.advancedMaxPriorityFee, let fee = unwrap.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
        return fee
      } else {
        return BigInt(0)
      }
    }
  }
}

enum EarnViewEvent {
  case openGasPriceSelect(gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, isSwap: Bool, minRatePercent: Double, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?)
  case getGasLimit(lendingPlatform: String, src: String, dest: String, srcAmount: String, minDestAmount: String, gasPrice: String, isSwap: Bool)
  case buildTx(lendingPlatform: String, src: String, dest: String, srcAmount: String, minDestAmount: String, gasPrice: String, isSwap: Bool)
  case confirmTx(fromToken: TokenData, toToken: TokenData, platform: LendingPlatformData, fromAmount: BigInt, toAmount: BigInt, gasPrice: BigInt, gasLimit: BigInt, transaction: SignTransaction?, eip1559Transaction: EIP1559Transaction?, isSwap: Bool, rawTransaction: TxObject, minReceiveDest: (String?, String?), priceImpact: Double, maxSlippage: Double)
  case openEarnSwap(token: TokenData)
  case getAllRates(from: TokenData, to: TokenData, amount: BigInt, focusSrc: Bool)
  case openChooseRate(from: TokenData, to: TokenData, rates: [Rate], gasPrice: BigInt, amountFrom: String)
  case getRefPrice(from: TokenData, to: TokenData)
  case checkAllowance(token: TokenData)
  case sendApprove(token: TokenData, remain: BigInt)
  case searchToken(isSwap: Bool)
}

protocol EarnViewControllerDelegate: class {
  func earnViewController(_ controller: AbstractEarnViewControler, run event: EarnViewEvent)
}

protocol AbstractEarnViewControler: class {
  func coordinatorDidUpdateSuccessTxObject(txObject: TxObject)
  func coordinatorFailUpdateTxObject(error: Error)
  func coordinatorDidUpdateGasLimit(_ value: BigInt, platform: String, tokenAdress: String)
  func coordinatorFailUpdateGasLimit()
  func coordinatorDidUpdateAllowance(token: TokenData, allowance: BigInt)
  func coordinatorDidFailUpdateAllowance(token: TokenData)
  func coordinatorSuccessApprove(token: TokenObject)
  func coordinatorFailApprove(token: TokenObject)
  func coordinatorUpdateIsUseGasToken(_ state: Bool)
  func coordinatorDidUpdateMinRatePercentage(_ value: CGFloat)
  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt)
  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String)
  func coordinatorSuccessSendTransaction()
  func coordinatorDidUpdateAdvancedNonce(_ nonce: String)
}

class EarnViewController: InAppBrowsingViewController, AbstractEarnViewControler {
  
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
  @IBOutlet weak var approveButtonLeftPaddingContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonRightPaddingContaint: NSLayoutConstraint!
  @IBOutlet weak var approveButton: UIButton!
  @IBOutlet weak var approveButtonEqualWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var approveButtonWidthContraint: NSLayoutConstraint!
  
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var compInfoLabel: UILabel!
  @IBOutlet weak var estGasFeeTitleLabel: UILabel!
  @IBOutlet weak var estGasFeeValueLabel: UILabel!
  @IBOutlet weak var gasFeeTittleLabelTopContraint: NSLayoutConstraint!
  
  let viewModel: EarnViewModel
  fileprivate var isViewSetup: Bool = false
  fileprivate var isViewDisappeared: Bool = false
  weak var delegate: EarnViewControllerDelegate?
  weak var navigationDelegate: NavigationBarDelegate?
  
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
    self.updateUITokenDidChange(self.viewModel.tokenData)
    self.updateUIForSendApprove(isShowApproveButton: false)
    self.fromAmountTextField.setupCustomDeleteIcon()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.isViewSetup = true
    self.isViewDisappeared = false
    self.updateUIPendingTxIndicatorView()
    self.updateGasFeeUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.updateUIBalanceDidChange()
    self.updateAllowance()
    Tracker.track(event: .openEarnView)
    
    MixPanelManager.track("earn_supply_open", properties: ["screenid": "earn_supply"])
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isViewDisappeared = true
    self.view.endEditing(true)
  }
  
  override func reloadChain() {
    super.reloadChain()
    
    chainButton?.setImage(nil, for: .normal)
    chainButton?.isEnabled = false
  }

  func updateUIBalanceDidChange() {
    guard self.isViewSetup else {
      return
    }
    self.fromBalanceLable.text = self.viewModel.totalBalanceText
  }

  fileprivate func updateGasFeeUI() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
    if KNGeneralProvider.shared.isUseEIP1559 {
      self.estGasFeeTitleLabel.isHidden = false
      self.estGasFeeValueLabel.isHidden = false
      self.gasFeeTittleLabelTopContraint.constant = 54
    } else {
      self.estGasFeeTitleLabel.isHidden = true
      self.estGasFeeValueLabel.isHidden = true
      self.gasFeeTittleLabelTopContraint.constant = 20
    }
    self.estGasFeeValueLabel.text = self.viewModel.displayEstGas
  }

  fileprivate func updateApproveButton() {
    self.approveButton.setTitle("Approve".toBeLocalised() + " " + self.viewModel.tokenData.symbol, for: .normal)
  }
  
  fileprivate func updateUIForSendApprove(isShowApproveButton: Bool) {
    guard self.isViewLoaded else {
      return
    }
    self.updateApproveButton()
    if isShowApproveButton {
      self.approveButtonLeftPaddingContraint.constant = 37
      self.approveButtonRightPaddingContaint.constant = 15
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 999)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.earnButton.isEnabled = false
      self.earnButton.alpha = 0.2
      if self.viewModel.approvingToken == nil {
        self.approveButton.isEnabled = true
        self.approveButton.alpha = 1
      } else {
        self.approveButton.isEnabled = false
        self.approveButton.alpha = 0.2
      }
    } else {
      self.approveButtonLeftPaddingContraint.constant = 0
      self.approveButtonRightPaddingContaint.constant = 37
      self.approveButtonEqualWidthContraint.priority = UILayoutPriority(rawValue: 250)
      self.approveButtonWidthContraint.priority = UILayoutPriority(rawValue: 999)
      self.earnButton.isEnabled = true
      self.earnButton.alpha = 1
    }
    
    self.view.layoutIfNeeded()
  }
  
  fileprivate func updateAllowance() {
    
    self.delegate?.earnViewController(self, run: .checkAllowance(token: self.viewModel.tokenData))
  }
  
  fileprivate func updateInforMessageUI() {
    if self.viewModel.isCompound {
      self.compInfoLabel.text = self.viewModel.displayCompInfo
      self.compInfoMessageContainerView.isHidden = false
      self.sendButtonTopContraint.constant = 150
    } else {
      self.compInfoMessageContainerView.isHidden = true
      self.sendButtonTopContraint.constant = 30
    }
  }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    let pendingTransaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().first { transaction in
      transaction.state == .pending
    }
    self.pendingTxIndicatorView.isHidden = pendingTransaction == nil
  }

  @IBAction func gasFeeAreaTapped(_ sender: UIButton) {
    self.delegate?.earnViewController(self, run: .openGasPriceSelect(
      gasLimit: self.viewModel.gasLimit,
      baseGasLimit: self.viewModel.baseGasLimit,
      selectType: self.viewModel.selectedGasPriceType,
      isSwap: false,
      minRatePercent: 0,
      advancedGasLimit: self.viewModel.advancedGasLimit,
      advancedPriorityFee: self.viewModel.advancedMaxPriorityFee,
      advancedMaxFee: self.viewModel.advancedMaxFee,
      advancedNonce: self.viewModel.advancedNonce
    ))
  }

  @IBAction func maxAmountButtonTapped(_ sender: UIButton) {
    self.keyboardSendAllButtonPressed(sender)
    MixPanelManager.track("earn_enter_amount", properties: ["screenid": "earn_supply"])
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    Tracker.track(event: .earnSubmit)
    guard !self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) else {
      return
    }
    self.buildTx()
    MixPanelManager.track("earn_supply", properties: [
      "screenid": "earn_supply",
      "token_id": viewModel.tokenData.address,
      "platform": viewModel.selectedPlatform,
      "amount": viewModel.amount
    ])
  }
  
  @IBAction func earnSwapMessageLabelTapped(_ sender: UITapGestureRecognizer) {
    self.delegate?.earnViewController(self, run: .openEarnSwap(token: self.viewModel.tokenData))
  }
  
  @IBAction func fromTokenButtonTapped(_ sender: UIButton) {
    self.delegate?.earnViewController(self, run: .searchToken(isSwap: false))
  }
  

  func keyboardSendAllButtonPressed(_ sender: Any) {
    self.viewModel.isEarnAllBalanace = true
    self.fromAmountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", forSendAllETH: self.viewModel.tokenData.isQuoteToken)
    self.fromAmountTextField.resignFirstResponder()
    self.updateGasLimit()
    
    if sender as? EarnViewController != self {
      if self.viewModel.tokenData.isQuoteToken {
        self.showSuccessTopBannerMessage(
          with: "",
          message: "A small amount of \(KNGeneralProvider.shared.quoteToken) will be used for transaction fee",
          time: 1.5
        )
      }
    }
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }
  
  @IBAction func walletsButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }
  
  @IBAction func approveButtonTapped(_ sender: UIButton) {
    guard let remain = self.viewModel.remainApprovedAmount else {
      return
    }
    self.delegate?.earnViewController(self, run: .sendApprove(token: remain.0, remain: remain.1))
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
    self.selectDepositTitleLabel.text = String(format: Strings.selectPlatformToSupply, token.symbol.uppercased())
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.updateUIBalanceDidChange()
  }

  func coordinatorAppSwitchAddress() {
    self.viewModel.resetBalances()
    self.updateUIBalanceDidChange()
    self.updateUIPendingTxIndicatorView()
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
    self.viewModel.resetAdvancedSettings()
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
    let tx = self.viewModel.buildSignSwapTx(txObject)
    let eip1559Tx = self.viewModel.buildEIP1559Tx(txObject)
    let event = EarnViewEvent.confirmTx(fromToken: self.viewModel.tokenData,
                                        toToken: self.viewModel.tokenData,
                                        platform: self.viewModel.selectedPlatformData,
                                        fromAmount: self.viewModel.amountBigInt,
                                        toAmount: self.viewModel.amountBigInt,
                                        gasPrice: self.viewModel.gasPrice,
                                        gasLimit: self.viewModel.gasLimit,
                                        transaction: tx,
                                        eip1559Transaction: eip1559Tx,
                                        isSwap: false,
                                        rawTransaction: txObject,
                                        minReceiveDest: ("", ""),
                                        priceImpact: 0.0,
                                        maxSlippage: 0.5)
    self.delegate?.earnViewController(self, run: event)
  }
  
  func coordinatorFailUpdateTxObject(error: Error) {
    self.navigationController?.showErrorTopBannerMessage(with: error.localizedDescription)
  }
  
  func coordinatorUpdateSelectedToken(_ token: TokenData) {
    self.viewModel.resetAdvancedSettings()
    self.viewModel.updateToken(token)
    self.updateUITokenDidChange(token)
    self.fromAmountTextField.text = ""
    self.viewModel.updateAmount("")
    self.updateUIBalanceDidChange()
    self.updateGasLimit()
    self.updateAllowance()
    self.updateGasFeeUI()
  }
  
  func coordinatorDidUpdateAllowance(token: TokenData, allowance: BigInt) {
    guard !self.viewModel.tokenData.isQuoteToken else {
      self.updateUIForSendApprove(isShowApproveButton: false)
      return
    }
    if self.viewModel.tokenData.getBalanceBigInt() > allowance {
      self.viewModel.remainApprovedAmount = (token, allowance)
      self.updateUIForSendApprove(isShowApproveButton: true)
    } else {
      self.updateUIForSendApprove(isShowApproveButton: false)
    }
  }
  
  func coordinatorDidFailUpdateAllowance(token: TokenData) {
    
  }
  
  fileprivate func showErrorMessage() {
    self.showWarningTopBannerMessage(
      with: "",
      message: "Something went wrong, please try again later".toBeLocalised(),
      time: 2.0
    )
  }

  func coordinatorSuccessApprove(token: TokenObject) {
    self.viewModel.approvingToken = token
    self.updateUIForSendApprove(isShowApproveButton: true)
  }

  func coordinatorFailApprove(token: TokenObject) {
    self.showErrorMessage()
    self.updateUIForSendApprove(isShowApproveButton: true)
  }
  
  func coordinatorUpdateIsUseGasToken(_ state: Bool) {
    self.updateGasFeeUI()
  }
  
  func coordinatorDidUpdateMinRatePercentage(_ value: CGFloat) {
    self.updateGasFeeUI()
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
    self.checkUpdateApproveButton()
    self.updateUIBalanceDidChange()
  }
  
  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.updateSelectedGasPriceType(.custom)
    self.updateGasFeeUI()
  }
  
  func coordinatorSuccessSendTransaction() {
    self.viewModel.advancedGasLimit = nil
    self.viewModel.advancedMaxPriorityFee = nil
    self.viewModel.advancedMaxFee = nil
    self.viewModel.updateSelectedGasPriceType(.medium)
    self.updateGasFeeUI()
    self.viewModel.resetAdvancedSettings()
  }
  
  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }

  fileprivate func checkUpdateApproveButton() {
    guard let token = self.viewModel.approvingToken else {
      return
    }
    if EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty {
      self.updateUIForSendApprove(isShowApproveButton: false)
      self.viewModel.approvingToken = nil
    }
    let pending = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().filter({ (item) -> Bool in
      return item.transactionDetailDescription.lowercased() == token.address.lowercased() && item.type == .allowance
    })
    if pending.isEmpty {
      self.updateUIForSendApprove(isShowApproveButton: false)
      self.viewModel.approvingToken = nil
    }
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
    MixPanelManager.track("earn_enter_amount", properties: ["screenid": "earn_supply"])
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    _ = self.showWarningInvalidAmountDataIfNeeded()
    self.updateGasLimit()
  }

  fileprivate func showWarningInvalidAmountDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming && self.isViewDisappeared { return false }

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
  
    if isConfirming {
      guard self.viewModel.isHavingEnoughETHForFee else {
        let fee = self.viewModel.gasFeeBigInt
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", value: "Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", comment: ""),
          message: String(format: "Deposit more \(KNGeneralProvider.shared.quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), fee.shortString(units: .ether, maxFractionDigits: 6))
        )
        return true
      }
    }
    return false
  }
}
