//
//  ClaimRewardsController.swift
//  KyberNetwork
//
//  Created by Com1 on 18/10/2021.
//

import UIKit
import Moya
import BigInt
import KrystalWallets
import Utilities
import BaseModule

class ClaimRewardsViewModel {
  var totalTokenBalance: Double
  var totalTokenSymbol: String
  var totalTokensValue: String
  var tokenIconURL: String
  var shouldDisableClaimButton = false
  
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

  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var baseGasLimit: BigInt
  var txObject: TxObject

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

  var transactionGasPriceString: String {
    let gasPriceText = self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 5
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: self.gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }

  init(totalTokenBalance: Double, totalTokenSymbol: String, totalTokensValue: String, tokenIconURL: String, gasLimit: BigInt, txObject: TxObject) {
    self.totalTokenBalance = totalTokenBalance
    self.totalTokenSymbol = totalTokenSymbol
    self.totalTokensValue = totalTokensValue
    self.tokenIconURL = tokenIconURL
    self.gasLimit = gasLimit
    self.baseGasLimit = gasLimit
    self.txObject = txObject
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
  
  func buildSumitTxObj() -> TxObject {
    var nonce = self.txObject.nonce
    if let unwrap = self.advancedNonce, let unwrapInt = Int(unwrap) {
      nonce = BigInt(unwrapInt).hexEncoded
    }
    return TxObject(nonce: nonce, from: self.txObject.from, to: self.txObject.to, data: self.txObject.data, value: self.txObject.value, gasPrice: self.gasPrice.hexEncoded, gasLimit: self.gasLimit.hexEncoded)
  }
}

protocol ClaimRewardsControllerDelegate: class {
  func didClaimRewards(_ controller: ClaimRewardsController, txObject: TxObject)
  func didDismiss()
  func didSelectAdvancedSetting(gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?)
}

class ClaimRewardsController: InAppBrowsingViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var tokenBalance: UILabel!
  @IBOutlet weak var tokenIcon: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var ethFeeLabel: UILabel!
  @IBOutlet weak var usdFeeLabel: UILabel!
  @IBOutlet weak var transactionGasPriceLabel: UILabel!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var claimRewardButton: UIButton!
  @IBOutlet weak var tokenValue: UILabel!
  @IBOutlet weak var bgView: UIView!
  @IBOutlet weak var countdownTimer: SRCountdownTimer!

  weak var delegate: ClaimRewardsControllerDelegate?
  let transitor = TransitionDelegate()
  let viewModel: ClaimRewardsViewModel

  init(viewModel: ClaimRewardsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ClaimRewardsController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    updateUI()
    setupTimer()
  }

  fileprivate func setupTimer() {
    self.countdownTimer.lineWidth = 2
    self.countdownTimer.lineColor = UIColor(named: "buttonBackgroundColor")!
    self.countdownTimer.labelTextColor = UIColor(named: "buttonBackgroundColor")!
    self.countdownTimer.trailLineColor = UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
    self.countdownTimer.isLoadingIndicator = true
    self.countdownTimer.isLabelHidden = true
    self.countdownTimer.isHidden = true
  }

  func updateUI() {
    self.cancelButton.rounded(radius: 16)
    self.claimRewardButton.rounded(radius: 16)
    self.claimRewardButton.isEnabled = !self.viewModel.shouldDisableClaimButton
    if self.viewModel.shouldDisableClaimButton {
      self.claimRewardButton.backgroundColor = UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
    } else {
      self.claimRewardButton.backgroundColor = UIColor(named: "buttonBackgroundColor")!
    }

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    bgView.addGestureRecognizer(tapGesture)

    tokenValue.text = self.viewModel.totalTokensValue
    tokenBalance.text = StringFormatter.amountString(value: self.viewModel.totalTokenBalance) + " " + self.viewModel.totalTokenSymbol
    if self.viewModel.tokenIconURL.isEmpty {
      tokenIcon.setSymbolImage(symbol: self.viewModel.totalTokenSymbol)
    } else {
      tokenIcon.setImage(with: self.viewModel.tokenIconURL, placeholder: UIImage(named: "default_token")!)
    }

    self.ethFeeLabel.text = self.viewModel.feeETHString
    self.usdFeeLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
  }
  
  func showLoading() {
    self.countdownTimer.isHidden = false
    self.countdownTimer.start(beginingValue: 1)
  }

  func stopLoading() {
    self.countdownTimer.isHidden = true
    self.countdownTimer.stopRotating()
  }

  fileprivate func isAccountUseGasToken() -> Bool {
    var data: [String: Bool] = [:]
    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
      data = saved
    } else {
      return false
    }
    return data[viewModel.currentAddress.addressString] ?? false
  }

  @IBAction func selectGasPriceButtonTapped(_ sender: Any) {
    self.delegate?.didSelectAdvancedSetting(
      gasLimit: self.viewModel.gasLimit,
      baseGasLimit: self.viewModel.baseGasLimit,
      selectType: self.viewModel.selectedGasPriceType,
      advancedGasLimit: self.viewModel.advancedGasLimit,
      advancedPriorityFee: self.viewModel.advancedMaxPriorityFee,
      advancedMaxFee: self.viewModel.advancedMaxFee,
      advancedNonce: self.viewModel.advancedNonce
    )
  }

  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func claimButtonTapped(_ sender: Any) {
    //check if balance > fee
    KNGeneralProvider.shared.getETHBalanace(for: KNGeneralProvider.shared.currentWalletAddress) { result in
      switch result {
      case .success(let balance):
        if balance.value > self.viewModel.transactionFee {
          self.delegate?.didClaimRewards(self, txObject: self.viewModel.buildSumitTxObj())
        } else {
          let errMsg = String(format: Strings.insufficientXForTransaction.toBeLocalised(), KNGeneralProvider.shared.quoteToken)
          self.showErrorTopBannerMessage(message: errMsg)
        }
      case .failure:
        if KNGeneralProvider.shared.quoteTokenObject.toToken().getBalanceBigInt() > self.viewModel.transactionFee {
          self.delegate?.didClaimRewards(self, txObject: self.viewModel.buildSumitTxObj())
        } else {
          let errMsg = String(format: Strings.insufficientXForTransaction.toBeLocalised(), KNGeneralProvider.shared.quoteToken)
          self.showErrorTopBannerMessage(message: errMsg)
        }
      }
    }
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: {
      self.delegate?.didDismiss()
    })
  }

  func coordinatorDidUpdateSetting(type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.selectedGasPriceType = type
    self.viewModel.gasPrice = value
    self.viewModel.resetAdvancedSettings()
    self.updateUI()
  }

  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.updateSelectedGasPriceType(.custom)
    self.updateUI()
  }
  
  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }
}

extension ClaimRewardsController: BottomPopUpAbstract {
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
