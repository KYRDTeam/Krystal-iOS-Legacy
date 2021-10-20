//
//  ClaimRewardsController.swift
//  KyberNetwork
//
//  Created by Com1 on 18/10/2021.
//

import UIKit
import Moya
import BigInt

class ClaimRewardsViewModel {
  var totalTokenBalance: Double
  var totalTokenSymbol: String
  var totalTokensValue: String
  var tokenIconURL: String

  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.claimRewardGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  private(set) var session: KNSession
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
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: self.gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }

  init(totalTokenBalance: Double, totalTokenSymbol: String, totalTokensValue: String, tokenIconURL: String, gasLimit: BigInt, session: KNSession, txObject: TxObject) {
    self.totalTokenBalance = totalTokenBalance
    self.totalTokenSymbol = totalTokenSymbol
    self.totalTokensValue = totalTokensValue
    self.tokenIconURL = tokenIconURL
    self.gasLimit = gasLimit
    self.session = session
    
    // reset gas price
    let newTxObject = txObject.newTxObjectWithGasPrice(gasPrice: self.gasPrice)
    self.txObject = newTxObject
  }
}

protocol ClaimRewardsControllerDelegate: class {
  func didClaimRewards(_ controller: ClaimRewardsController, txObject: TxObject)
}

class ClaimRewardsController: KNBaseViewController {
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
  }

  func updateUI() {
    self.cancelButton.rounded(radius: 16)
    self.claimRewardButton.rounded(radius: 16)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    bgView.addGestureRecognizer(tapGesture)
    
    tokenValue.text = self.viewModel.totalTokensValue
    tokenBalance.text = StringFormatter.currencyString(value: self.viewModel.totalTokenBalance, symbol: self.viewModel.totalTokenSymbol) + " " + self.viewModel.totalTokenSymbol
    if self.viewModel.tokenIconURL.isEmpty {
      tokenIcon.setSymbolImage(symbol: self.viewModel.totalTokenSymbol)
    } else {
      tokenIcon.setImage(with: self.viewModel.tokenIconURL, placeholder: UIImage(named: "default_token")!)
    }

    self.ethFeeLabel.text = self.viewModel.feeETHString
    self.usdFeeLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
  }
  
  fileprivate func isAccountUseGasToken() -> Bool {
    return true
//    var data: [String: Bool] = [:]
//    if let saved = UserDefaults.standard.object(forKey: Constants.useGasTokenDataKey) as? [String: Bool] {
//      data = saved
//    } else {
//      return false
//    }
//    return data[self.session.wallet.address.description] ?? false
  }

  @IBAction func selectGasPriceButtonTapped(_ sender: Any) {
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: self.viewModel.gasLimit, selectType: self.viewModel.selectedGasPriceType, currentRatePercentage: 3, isUseGasToken: self.isAccountUseGasToken(), isContainSlippageSection: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )

    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.present(vc, animated: true, completion: nil)
  }

  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func claimButtonTapped(_ sender: Any) {
    //TODO check if balance > fee
    if self.viewModel.totalTokenBalance > self.viewModel.transactionFee.hexEncoded.doubleValue {
      self.delegate?.didClaimRewards(self, txObject: self.viewModel.txObject)
    }
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }


}

extension ClaimRewardsController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 450
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension ClaimRewardsController: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
        self.viewModel.selectedGasPriceType = type
        self.viewModel.gasPrice = value
        self.viewModel.txObject = self.viewModel.txObject.newTxObjectWithGasPrice(gasPrice: value)
        self.updateUI()
    default:
      break
    }
  }
}
