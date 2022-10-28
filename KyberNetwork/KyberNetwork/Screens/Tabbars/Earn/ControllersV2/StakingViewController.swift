//
//  StakingViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 26/10/2022.
//

import UIKit
import BigInt

enum FormState {
  case valid
  case error(msg: String)
  case empty
}

class StakingViewModel {
  let pool: EarnPoolModel
  let selectedPlatform: EarnPlatform
  let apiService = KrystalService()
  var optionDetail: Observable<[EarningToken]?> = .init(nil)
  var error: Observable<Error?> = .init(nil)
  var amount: Observable<String> = .init("")
  var selectedEarningToken: Observable<EarningToken?> = .init(nil)
  var formState: Observable<FormState> = .init(.empty)
  
  init(pool: EarnPoolModel, platform: EarnPlatform) {
    self.pool = pool
    self.selectedPlatform = platform
  }
  
  var displayMainHeader: String {
    return "Stake \(pool.token.symbol.uppercased()) on \(selectedPlatform.name.uppercased())"
  }
  
  var displayStakeToken: String {
    return pool.token.getBalanceBigInt().shortString(decimals: pool.token.decimals) + " " + pool.token.symbol.uppercased()
  }
  
  var amountBigInt: BigInt {
    return self.amount.value.amountBigInt(decimals: pool.token.decimals) ?? BigInt(0)
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
  
  var displayAmountReceive: String {
    guard let detail = selectedEarningToken.value, !amount.value.isEmpty, let amountDouble = Double(amount.value) else { return "---" }
    let receiveAmt = detail.exchangeRate * amountDouble
    return receiveAmt.description + " " + detail.symbol
  }
  
  var displayRate: String {
    guard let detail = selectedEarningToken.value else { return "---" }
    return "1 \(pool.token.symbol) = \(detail.exchangeRate) \(detail.symbol)"
  }
  
  var isAmountTooSmall: Bool {
    
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    return self.amountBigInt > pool.token.getBalanceBigInt()
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
  
  var viewModel: StakingViewModel!
  var keyboardTimer: Timer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    bindingViewModel()
    viewModel.requestOptionDetail()
  }
  
  private func setupUI() {
    apyInfoView.setTitle(title: "APY (Est. Yield", underlined: false)
    apyInfoView.iconImageView.isHidden = true
    
    amountReceiveInfoView.setTitle(title: "You will receive", underlined: false)
    amountReceiveInfoView.iconImageView.isHidden = true
    
    rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
    rateInfoView.iconImageView.isHidden = true
    
    networkFeeInfoView.setTitle(title: "Network Fee", underlined: false)
    networkFeeInfoView.iconImageView.isHidden = true
    
    earningTokenContainerView.delegate = self
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
    case .error(let msg):
      amountFieldContainerView.rounded(color: UIColor.Kyber.textRedColor, width: 1, radius: 16)
      errorMsgLabel.text = msg
      nextButton.alpha = 0.2
    case .empty:
      amountFieldContainerView.rounded(radius: 16)
      errorMsgLabel.text = ""
      nextButton.alpha = 0.2
    }
  }
  
  private func bindingViewModel() {
    stakeMainHeaderLabel.text = viewModel.displayMainHeader
    stakeTokenLabel.text = viewModel.displayStakeToken
    stakeTokenImageView.setImage(urlString: viewModel.pool.token.logo, symbol: viewModel.pool.token.symbol)
    apyInfoView.setValue(value: viewModel.selectedPlatform.apy.description, highlighted: true)
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
    }
    viewModel.formState.observeAndFire(on: self) { _ in
      self.updateUIError()
    }
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func maxButtonTapped(_ sender: UIButton) {
    viewModel.amount.value = viewModel.pool.token.getBalanceBigInt().fullString(decimals: viewModel.pool.token.decimals)
    amountTextField.text = viewModel.amount.value
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
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
//    showWarningInvalidAmountDataIfNeeded()
  }
  
//  fileprivate func showWarningInvalidAmountDataIfNeeded() {
//    guard !self.viewModel.amount.value.isEmpty else {
//      viewModel.formState.value = .empty
//      return
//    }
////    guard self.viewModel.isEnoughFee else {
////      self.showWarningTopBannerMessage(
////        with: NSLocalizedString("Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", value: "Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", comment: ""),
////        message: String(format: "Deposit more \(KNGeneralProvider.shared.quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), self.viewModel.transactionFee.shortString(units: .ether, maxFractionDigits: 6))
////      )
////      return true
////    }
//
//    guard !self.viewModel.isAmountTooSmall else {
//      viewModel.formState.value = .error(msg: "amount.to.send.greater.than.zero".toBeLocalised())
//      return
//    }
//    guard !self.viewModel.isAmountTooBig else {
//      viewModel.formState.value = .error(msg: "balance.not.enough.to.make.transaction".toBeLocalised())
//      return
//    }
//    viewModel.formState.value = .valid
//  }
}

extension StakingViewController: StakingEarningTokensViewDelegate {
  func didSelectEarningToken(_ token: EarningToken) {
    viewModel.selectedEarningToken.value = token
  }
}
