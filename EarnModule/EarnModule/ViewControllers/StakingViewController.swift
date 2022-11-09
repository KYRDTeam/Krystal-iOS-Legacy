//
//  StakingViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 26/10/2022.
//

import UIKit
import BigInt
import Utilities
import AppState
import Services
import DesignSystem
import Dependencies
import TransactionModule


typealias StakeDisplayInfo = (amount: String, apy: String, receiveAmount: String, rate: String, fee: String, platform: String, stakeTokenIcon: String, fromSym: String, toSym: String)

typealias ProjectionValue = (value: String, usd: String)
typealias ProjectionValues = (p30: ProjectionValue, p60: ProjectionValue, p90: ProjectionValue)

protocol StakingViewControllerDelegate: class {
//  func didSelectNext(_ viewController: StakingViewController, settings: UserSettings, txObject: TxObject, displayInfo: StakeDisplayInfo)
  func sendApprove(_ viewController: StakingViewController, tokenAddress: String, remain: BigInt, symbol: String, toAddress: String)
}

enum FormState: Equatable {
  case valid
  case error(msg: String)
  case empty
  
  static public func == (lhs: FormState, rhs: FormState) -> Bool {
    switch (lhs, rhs) {
    case (.valid, .valid), (.empty, .empty):
      return true
    default:
      return false
    }
  }
}

enum NextButtonState {
  case notApprove
  case needApprove
  case approved
  case noNeed
}

class StakingViewModel {
  let pool: EarnPoolModel
  let selectedPlatform: EarnPlatform
  let apiService = EarnServices()
  var optionDetail: Observable<[EarningToken]?> = .init(nil)
  var error: Observable<Error?> = .init(nil)
  var amount: Observable<String> = .init("")
  var selectedEarningToken: Observable<EarningToken?> = .init(nil)
  var formState: Observable<FormState> = .init(.empty)
  var gasPrice: Observable<BigInt> = .init(AppDependencies.gasConfig.getStandardGasPrice(chain: AppState.shared.currentChain))
  var gasLimit: Observable<BigInt> = .init(AppDependencies.gasConfig.earnGasLimitDefault)
  var baseGasLimit: BigInt = AppDependencies.gasConfig.earnGasLimitDefault
  var txObject: Observable<TxObject?> = .init(nil)
  var isLoading: Observable<Bool> = .init(false)
  
  
  var setting: TxSettingObject = .default
  
  
//  var basicSetting: BasicTransactionSettings = BasicTransactionSettings(gasPriceType: .medium) {
//    didSet {
//      let gas = self.basicSetting.gasPriceType.getGasValue()
//      self.gasPrice.value = gas
//    }
//  }
//  var advancedSetting: AdvancedTransactionSettings? = nil {
//    didSet {
//      guard let setting = self.advancedSetting else { return }
//      self.gasPrice.value = setting.maxFee
//      self.gasLimit.value = setting.gasLimit
//    }
//  }
  
  
  
  
  
  var isUseReverseRate: Observable<Bool> = .init(false)
  
  var nextButtonStatus: Observable<NextButtonState> = .init(.notApprove)
  
  var tokenAllowance: BigInt? {
    didSet {
      self.checkNextButtonStatus()
    }
  }
  
  var isExpandProjection: Observable<Bool> = .init(false)
  
  init(pool: EarnPoolModel, platform: EarnPlatform) {
    self.pool = pool
    self.selectedPlatform = platform
  }
  
  var displayMainHeader: String {
    return "Stake \(pool.token.symbol.uppercased()) on \(selectedPlatform.name.uppercased())"
  }
  
  var displayStakeToken: String {
    return AppDependencies.balancesStorage.getBalanceBigInt(address: pool.token.address).shortString(decimals: pool.token.decimals) + " " + pool.token.symbol.uppercased()
  }
  
  var displayAPY: String {
    return StringFormatter.percentString(value: selectedPlatform.apy / 100)
  }
  
  var amountBigInt: BigInt {
    return self.amount.value.amountBigInt(decimals: pool.token.decimals) ?? BigInt(0)
  }
  
  var transactionFee: BigInt {
    return self.gasPrice.value * self.gasLimit.value
  }
  
  var feeETHString: String {
    let string: String = self.transactionFee.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return "\(string) \(AppState.shared.currentChain.quoteToken())"
  }

  var feeUSDString: String {
    let quoteUSD = AppDependencies.priceStorage.getQuoteUsdRate(chain: AppState.shared.currentChain) ?? 0
    let usd = self.transactionFee * BigInt(quoteUSD * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String =  usd.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return "(~ \(valueString) USD)"
  }
  
  var displayFeeString: String {
    return "\(feeETHString) \(feeUSDString)"
  }
  
  func requestOptionDetail() {
    apiService.getStakingOptionDetail(platform: selectedPlatform.name, earningType: selectedPlatform.type, chainID: "\(pool.chainID)", tokenAddress: pool.token.address) { result in
      switch result {
      case .success(let detail):
        self.optionDetail.value = detail
        self.selectedEarningToken.value = detail.first
      case .failure(let error):
        self.error.value = error
      }
    }
  }
  
  func checkNextButtonStatus() {
    guard let tokenAllowance = tokenAllowance else {
      self.nextButtonStatus.value = .notApprove
      getAllowance()
      return
    }
    if amountBigInt > tokenAllowance {
      self.nextButtonStatus.value = .needApprove
    } else {
      self.nextButtonStatus.value = .noNeed
    }
  }
  
  var buildTxRequestParams: JSONDictionary {
    
    var params: JSONDictionary = [
      "tokenAmount": amountBigInt.description,
      "chainID": pool.chainID,
      "earningType": selectedPlatform.type,
      "platform": selectedPlatform.name,
      "userAddress": AppState.shared.currentAddress.addressString,
      "tokenAddress": pool.token.address
    ]
    if selectedPlatform.name.lowercased() == "ankr" {
      var useC = false
      if selectedEarningToken.value?.name.suffix(1).description.lowercased() == "c" {
        useC = true
      }
      
      params["extraData"] = ["ankr": ["useTokenC": useC]]
    }
    return params
  }
  
  func requestBuildStakeTx(showLoading: Bool = false, completion: @escaping () -> () = {}) {
    if showLoading { isLoading.value = true }
    apiService.buildStakeTx(param: buildTxRequestParams) { result in
      switch result {
      case .success(let tx):
        self.txObject.value = tx
        self.gasLimit.value = BigInt(tx.gasLimit.drop0x, radix: 16) ?? AppDependencies.gasConfig.earnGasLimitDefault
        completion()
      case .failure(let error):
        self.error.value = error
      }
      if showLoading { self.isLoading.value = false }
    }
  }
  
  var displayAmountReceive: String {
    guard let detail = selectedEarningToken.value, !amount.value.isEmpty, let amountDouble = Double(amount.value) else { return "---" }
    let receiveAmt = rate * amountDouble
    return receiveAmt.description + " " + detail.symbol
  }
  
  var rate: Double {
    guard let detail = selectedEarningToken.value else { return 0.0 }
    return detail.exchangeRate / pow(10.0, 18.0)
  }
  
  var displayRate: String {
    guard let detail = selectedEarningToken.value else { return "---" }
    if isUseReverseRate.value {
      return "1 \(detail.symbol) = \(1 / rate) \(pool.token.symbol)"
    } else {
      return "1 \(pool.token.symbol) = \(rate) \(detail.symbol)"
    }
  }
  
  var isAmountTooSmall: Bool {
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    return self.amountBigInt > AppDependencies.balancesStorage.getBalanceBigInt(address: pool.token.address)
  }
  
  var displayProjectionValues: ProjectionValues? {
    guard !amount.value.isEmpty else {
      return nil
    }
    let amt = amountBigInt
    let apy = selectedPlatform.apy
    let decimal = pool.token.decimals
    let symbol = pool.token.symbol
    
    let p30Param = apy * 30.0 / 365
    let p60Param = apy * 60.0 / 365
    let p90Param = apy * 90.0 / 365
    
    let p30 = amt * BigInt(p30Param * pow(10.0, 18.0)) / BigInt(10).power(18)
    let p60 = amt * BigInt(p60Param * pow(10.0, 18.0)) / BigInt(10).power(18)
    let p90 = amt * BigInt(p90Param * pow(10.0, 18.0)) / BigInt(10).power(18)
    
    let displayP30 = p30.shortString(decimals: decimal) + " \(symbol)"
    let displayP60 = p60.shortString(decimals: decimal) + " \(symbol)"
    let displayP90 = p90.shortString(decimals: decimal) + " \(symbol)"
    
    var displayP30USD = ""
    var displayP60USD = ""
    var displayP90USD = ""
    
    if let usdPrice = AppDependencies.priceStorage.getUsdPrice(address: pool.token.address) {
      let usd30 = p30 * BigInt(usdPrice * pow(10.0, 18.0)) / BigInt(10).power(decimal)
      let usd60 = p60 * BigInt(usdPrice * pow(10.0, 18.0)) / BigInt(10).power(decimal)
      let usd90 = p90 * BigInt(usdPrice * pow(10.0, 18.0)) / BigInt(10).power(decimal)
      
      displayP30USD = "≈ " + usd30.string(units: EthereumUnit.ether, minFractionDigits: 0, maxFractionDigits: 4) + " USD"
      displayP60USD = "≈ " + usd60.string(units: EthereumUnit.ether, minFractionDigits: 0, maxFractionDigits: 4) + " USD"
      displayP90USD = "≈ " + usd90.string(units: EthereumUnit.ether, minFractionDigits: 0, maxFractionDigits: 4) + " USD"
    }
    
    return ( (displayP30, displayP30USD), (displayP60, displayP60USD), (displayP90, displayP90USD) )
    
  }
  
  func getAllowance() {
    guard !pool.token.isQuoteToken() else {
      nextButtonStatus.value = .noNeed
      return
    }
    guard let tx = txObject.value else {
      requestBuildStakeTx(showLoading: false, completion: {
        self.getAllowance()
      })
      return
    }
    
    let contractAddress = tx.to

    let allowanceService = AllowanceService()
    allowanceService.getAllowance(chain: AppState.shared.currentChain,for: AppState.shared.currentAddress.addressString, networkAddress: contractAddress, tokenAddress: pool.token.address) { result in
      switch result {
      case .success(let number):
        self.tokenAllowance = number
      case .failure(let error):
        self.error.value = error
        self.tokenAllowance = nil
      }
    }
  }
  
  var isChainValid: Bool {
    return AppState.shared.currentChain.customRPC().chainID == pool.chainID
  }
}

class StakingViewController: InAppBrowsingViewController {
  
  @IBOutlet weak var stakeMainHeaderLabel: UILabel!
  @IBOutlet weak var stakeTokenLabel: UILabel!
  @IBOutlet weak var stakeTokenImageView: UIImageView!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var apyInfoView: SwapInfoView!
  @IBOutlet weak var amountReceiveInfoView: SwapInfoView!
  @IBOutlet weak var rateInfoView: SwapInfoView!
  @IBOutlet weak var networkFeeInfoView: SwapInfoView!
  
  @IBOutlet weak var earningTokenContainerView: StakingEarningTokensView!
  @IBOutlet weak var infoAreaTopContraint: NSLayoutConstraint!
  @IBOutlet weak var errorMsgLabel: UILabel!
  @IBOutlet weak var amountFieldContainerView: UIView!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var expandProjectionButton: UIButton!
  @IBOutlet weak var expandContainerViewHeightContraint: NSLayoutConstraint!
  
  @IBOutlet weak var p30ValueLabel: UILabel!
  @IBOutlet weak var p30USDValueLabel: UILabel!
  
  @IBOutlet weak var p60ValueLabel: UILabel!
  @IBOutlet weak var p60USDValueLabel: UILabel!
  
  @IBOutlet weak var p90ValueLabel: UILabel!
  @IBOutlet weak var p90USDValueLabel: UILabel!
  
  @IBOutlet weak var projectionContainerView: UIView!
  
  var viewModel: StakingViewModel!
  var keyboardTimer: Timer?
  
  weak var delegate: StakingViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    bindingViewModel()
    viewModel.requestOptionDetail()
    viewModel.getAllowance()
    updateUIProjection()
  }
  
  private func setupUI() {
    apyInfoView.setTitle(title: Strings.apyTitle, underlined: false)
//    apyInfoView.iconImageView.isHidden = true
    
    amountReceiveInfoView.setTitle(title: Strings.youWillReceive, underlined: false)
//    amountReceiveInfoView.iconImageView.isHidden = true
    
    rateInfoView.setTitle(title: Strings.rate, underlined: false, shouldShowIcon: true)
    rateInfoView.onTapRightIcon = {
      self.viewModel.isUseReverseRate.value = !self.viewModel.isUseReverseRate.value
    }
    
    networkFeeInfoView.setTitle(title: Strings.networkFee, underlined: false)
//    networkFeeInfoView.iconImageView.isHidden = true
    
    earningTokenContainerView.delegate = self
    updateUIGasFee()
  }
  
  fileprivate func updateRateInfoView() {
    self.amountReceiveInfoView.setValue(value: self.viewModel.displayAmountReceive)
    self.rateInfoView.setValue(value: self.viewModel.displayRate)
  }
  
  fileprivate func updateUIEarningTokenView() {
    if let data = viewModel.optionDetail.value, data.count <= 1 {
      earningTokenContainerView.isHidden = true
      infoAreaTopContraint.constant = 40
    } else {
      earningTokenContainerView.isHidden = false
      infoAreaTopContraint.constant = 211
    }
  }
  
  fileprivate func updateUIError() {
    switch viewModel.formState.value {
    case .valid:
      amountFieldContainerView.rounded(radius: 16)
      errorMsgLabel.text = ""
      nextButton.alpha = 1
      nextButton.isEnabled = true
    case .error(let msg):
      amountFieldContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
      errorMsgLabel.text = msg
      nextButton.alpha = 0.2
    case .empty:
      amountFieldContainerView.rounded(radius: 16)
      errorMsgLabel.text = ""
      nextButton.alpha = 0.2
    }
  }
  
  fileprivate func updateUIGasFee() {
    networkFeeInfoView.setValue(value: viewModel.displayFeeString)
  }
  
  fileprivate func updateUIProjection() {
    guard let projectionData = viewModel.displayProjectionValues else {
      projectionContainerView.isHidden = true
      return
    }
    p30ValueLabel.text = projectionData.p30.value
    p30USDValueLabel.text = projectionData.p30.usd
    
    p60ValueLabel.text = projectionData.p60.value
    p60USDValueLabel.text = projectionData.p60.usd
    
    p90ValueLabel.text = projectionData.p90.value
    p90USDValueLabel.text = projectionData.p90.usd
    
    projectionContainerView.isHidden = false
    viewModel.isExpandProjection.value = true
  }
  
  private func bindingViewModel() {
    stakeMainHeaderLabel.text = viewModel.displayMainHeader
    stakeTokenLabel.text = viewModel.displayStakeToken
    stakeTokenImageView.setImage(urlString: viewModel.pool.token.logo, symbol: viewModel.pool.token.symbol)
    apyInfoView.setValue(value: viewModel.displayAPY, highlighted: true)
    viewModel.selectedEarningToken.observeAndFire(on: self) { _ in
      self.updateRateInfoView()
    }
    viewModel.optionDetail.observeAndFire(on: self) { data in
      if let unwrap = data {
        self.earningTokenContainerView.updateData(unwrap)
      }
      self.updateUIEarningTokenView()
    }
    viewModel.amount.observeAndFire(on: self) { _ in
      self.updateRateInfoView()
      self.updateUIError()
      self.viewModel.checkNextButtonStatus()
      self.updateUIProjection()
    }
    viewModel.formState.observeAndFire(on: self) { _ in
      self.updateUIError()
    }
    
    viewModel.txObject.observeAndFire(on: self, observerBlock: { value in
      guard let tx = value else { return }
      print("[Stake] \(tx)")
    })
    
    viewModel.isLoading.observeAndFire(on: self) { value in
      if value {
        self.displayLoading()
      } else {
        self.hideLoading()
        guard !self.viewModel.amount.value.isEmpty else { return }
        self.nextButtonTapped(self.nextButton)
      }
    }
    
    viewModel.gasLimit.observeAndFire(on: self) { _ in
      self.updateUIGasFee()
    }
    
    viewModel.gasPrice.observeAndFire(on: self) { _ in
      self.updateUIGasFee()
    }
    
    viewModel.nextButtonStatus.observeAndFire(on: self) { value in
      switch value {
      case .notApprove:
        self.nextButton.setTitle(String(format: Strings.cheking, self.viewModel.pool.token.symbol), for: .normal)
        self.nextButton.alpha = 0.2
        self.nextButton.isEnabled = false
      case .needApprove:
        self.nextButton.setTitle(String(format: Strings.approveToken, self.viewModel.pool.token.symbol), for: .normal)
        self.nextButton.alpha = 1
        self.nextButton.isEnabled = true
      case .approved:
        self.nextButton.setTitle(Strings.stakeNow, for: .normal)
        self.updateUIError()
      case .noNeed:
        self.nextButton.setTitle(Strings.stakeNow, for: .normal)
        self.updateUIError()
      }
    }
    
    viewModel.isExpandProjection.observeAndFire(on: self) { value in
      UIView.animate(withDuration: 0.25) {
        if value {
          self.expandContainerViewHeightContraint.constant = 380.0
          self.expandProjectionButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        } else {
          self.expandContainerViewHeightContraint.constant = 48.0
          self.expandProjectionButton.transform = CGAffineTransform(rotationAngle: 0)
        }
      }
    }
    
    viewModel.isUseReverseRate.observeAndFire(on: self) { _ in
      self.rateInfoView.setValue(value: self.viewModel.displayRate)
    }
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func maxButtonTapped(_ sender: UIButton) {
    viewModel.amount.value = AppDependencies.balancesStorage.getBalanceBigInt(address: viewModel.pool.token.address).fullString(decimals: viewModel.pool.token.decimals)
    amountTextField.text = viewModel.amount.value
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    guard viewModel.isChainValid else {
      let chainType = ChainType.make(chainID: viewModel.pool.chainID) ?? .eth
      let alertController = KNPrettyAlertController(
        title: "",
        message: "Please switch to \(chainType.chainName()) to continue".toBeLocalised(),
        secondButtonTitle: Strings.ok,
        firstButtonTitle: Strings.cancel,
        secondButtonAction: {
          AppState.shared.updateChain(chain: chainType)
        },
        firstButtonAction: {
        }
      )
      alertController.popupHeight = 220
      present(alertController, animated: true, completion: nil)
      return
    }
    if viewModel.nextButtonStatus.value == .needApprove {
      delegate?.sendApprove(self, tokenAddress: viewModel.pool.token.address, remain: viewModel.tokenAllowance ?? .zero, symbol: viewModel.pool.token.symbol, toAddress: viewModel.txObject.value?.to ?? "")
    } else {
      guard viewModel.formState.value == .valid else { return }
      if let tx = viewModel.txObject.value {
        let displayInfo = ("\(viewModel.amount.value) \(viewModel.pool.token.symbol)", viewModel.displayAPY, viewModel.displayAmountReceive, viewModel.displayRate, viewModel.displayFeeString, viewModel.selectedPlatform.name, viewModel.pool.token.logo, viewModel.pool.token.symbol, viewModel.selectedEarningToken.value?.symbol ?? "")
        self.openStakeSummary(txObject: tx, settings: viewModel.setting, displayInfo: displayInfo)
      } else {
        viewModel.requestBuildStakeTx(showLoading: true)
      }
    }
    
  }
  
  @IBAction func expandProjectionButtonTapped(_ sender: UIButton) {
    viewModel.isExpandProjection.value = !viewModel.isExpandProjection.value
  }
  
  func coordinatorSuccessApprove(address: String) {
    viewModel.nextButtonStatus.value = .approved
    viewModel.tokenAllowance = nil
  }
  
  func coordinatorFailApprove(address: String) {
    viewModel.nextButtonStatus.value = .notApprove
  }
  
  func openStakeSummary(txObject: TxObject, settings: TxSettingObject, displayInfo: StakeDisplayInfo) {
//    let vm = StakingSummaryViewModel(txObject: txObject, settings: settings, displayInfo: displayInfo)
//    let vc = StakingSummaryViewController(viewModel: vm)
//    let sheet = SheetViewController(controller: vc, sizes: [.fixed(560)], options: .init(pullBarHeight: 0))
//    vc.delegate = self
//    navigationController.present(sheet, animated: true)
  }
}

extension StakingViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.amount.value = ""
    return false
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let cleanedText = text.cleanStringToNumber()
    if cleanedText.amountBigInt(decimals: self.viewModel.pool.token.decimals) == nil { return false }
    textField.text = cleanedText
    self.viewModel.amount.value = cleanedText
    self.keyboardTimer?.invalidate()
    self.keyboardTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(StakingViewController.keyboardPauseTyping),
            userInfo: ["textField": textField],
            repeats: false)
    return false
  }
  
  @objc func keyboardPauseTyping(timer: Timer) {
    updateRateInfoView()
    viewModel.requestBuildStakeTx()
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    showWarningInvalidAmountDataIfNeeded()
  }
  
  fileprivate func showWarningInvalidAmountDataIfNeeded() {
    guard !self.viewModel.amount.value.isEmpty else {
      viewModel.formState.value = .empty
      return
    }
//    guard self.viewModel.isEnoughFee else {
//      self.showWarningTopBannerMessage(
//        with: NSLocalizedString("Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", value: "Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", comment: ""),
//        message: String(format: "Deposit more \(KNGeneralProvider.shared.quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), self.viewModel.transactionFee.shortString(units: .ether, maxFractionDigits: 6))
//      )
//      return true
//    }

    guard !self.viewModel.isAmountTooSmall else {
      viewModel.formState.value = .error(msg: "amount.to.send.greater.than.zero".toBeLocalised())
      return
    }
    guard !self.viewModel.isAmountTooBig else {
      viewModel.formState.value = .error(msg: "balance.not.enough.to.make.transaction".toBeLocalised())
      return
    }
    viewModel.formState.value = .valid
  }
}

extension StakingViewController: StakingEarningTokensViewDelegate {
  func didSelectEarningToken(_ token: EarningToken) {
    viewModel.selectedEarningToken.value = token
  }
}
