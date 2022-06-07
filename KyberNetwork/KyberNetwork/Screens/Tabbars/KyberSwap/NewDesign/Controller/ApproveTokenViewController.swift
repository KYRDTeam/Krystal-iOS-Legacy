//
//  ApproveTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/25/20.
//

import UIKit
import BigInt
import TrustCore

protocol ApproveTokenViewModel {
  func getFee() -> BigInt
  func getFeeString() -> String
  func getFeeUSDString() -> String
  var subTitleText: String { get }
  var token: TokenObject? { get }
  var remain: BigInt { get }
  var address: String { get }
  var state: Bool { get }
  var symbol: String { get }
  var toAddress: String? { get }
  var tokenAddress: Address? { get }
  var gasLimit: BigInt { get set }
  var value: BigInt { get set }
}

class ApproveTokenViewModelForTokenObject: ApproveTokenViewModel {
  var gasLimit: BigInt = KNGasConfiguration.approveTokenGasLimitDefault
  var value: BigInt = Constants.maxValueBigInt

  var tokenAddress: Address? {
    return Address(string: self.address)
  }

  let token: TokenObject?
  let remain: BigInt
  var gasPrice: BigInt = KNGasCoordinator.shared.defaultKNGas
  var toAddress: String?

  func getFee() -> BigInt {
    let fee = self.gasPrice * self.gasLimit
    return fee
  }

  func getFeeString() -> String {
    let fee = self.getFee()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getFeeUSDString() -> String {
    guard let tokenPrice = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let feeUSD = self.getFee() * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    return "~ \(feeUSD.displayRate(decimals: 18)) USD"
  }

  var subTitleText: String {
    return String(format: "You need to approve Krystal to spend %@", self.token?.symbol.uppercased() ?? "")
  }

  var address: String {
    return self.token?.address ?? ""
  }
  
  var state: Bool {
    return false
  }
  
  var symbol: String {
    return self.token?.symbol ?? ""
  }

  init(token: TokenObject, res: BigInt) {
    self.token = token
    self.remain = res
  }
}

class ApproveTokenViewModelForTokenAddress: ApproveTokenViewModel {
  var gasLimit: BigInt = KNGasConfiguration.approveTokenGasLimitDefault
  var value: BigInt = Constants.maxValueBigInt

  var tokenAddress: Address? {
    return Address(string: self.address)
  }

  var token: TokenObject?
  let address: String
  let remain: BigInt
  var gasPrice: BigInt = KNGasCoordinator.shared.defaultKNGas
  let state: Bool
  let symbol: String
  var toAddress: String?

  init(address: String, remain: BigInt, state: Bool, symbol: String) {
    self.address = address
    self.remain = remain
    self.state = state
    self.symbol = symbol
  }

  func getFee() -> BigInt {
    let fee = self.gasPrice * self.gasLimit
    return fee
  }

  func getFeeString() -> String {
    let fee = self.getFee()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getFeeUSDString() -> String {
    guard let tokenPrice = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let feeUSD = self.getFee() * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    return "~ \(feeUSD.displayRate(decimals: 18)) USD"
  }

  var subTitleText: String {
    return "You need to approve Krystal to spend \(self.symbol.uppercased())"
  }
}

protocol ApproveTokenViewControllerDelegate: class {
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt, gasLimit: BigInt)
  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt)
  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: Address, value: BigInt)
}

class ApproveTokenViewController: KNBaseViewController {
  @IBOutlet weak var headerTitle: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var contractAddressLabel: UILabel!
  @IBOutlet weak var gasFeeTitleLabel: UILabel!
  @IBOutlet weak var gasFeeLabel: UILabel!
  @IBOutlet weak var gasFeeEstUSDLabel: UILabel!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var editIcon: UIImageView!
  @IBOutlet weak var editLabel: UILabel!
  @IBOutlet weak var editButton: UIButton!
  
  var viewModel: ApproveTokenViewModel
  let transitor = TransitionDelegate()
  weak var delegate: ApproveTokenViewControllerDelegate?
  
  var approveValue: BigInt {
    return self.viewModel.value
  }

  init(viewModel: ApproveTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ApproveTokenViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.gasFeeLabel.text = self.viewModel.getFeeString()
    self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
    self.cancelButton.rounded(radius: 16)
    self.confirmButton.rounded(radius: 16)
    self.descriptionLabel.text = self.viewModel.subTitleText
    let address = self.viewModel.toAddress ?? KNGeneralProvider.shared.proxyAddress
    self.contractAddressLabel.text = address
    
    if let tokenAddress = self.viewModel.tokenAddress {
      self.delegate?.approveTokenViewControllerGetEstimateGas(self, tokenAddress: tokenAddress, value: self.viewModel.value)
    }
  }

  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    let ethBalance = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
    guard self.viewModel.getFee() < ethBalance else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: NSLocalizedString("balance.not.enough.to.make.transaction", value: "Balance is not enough to make the transaction.", comment: "")
      )
      return
    }
    if let token = self.viewModel.token {
      self.delegate?.approveTokenViewControllerDidApproved(self, token: token, remain: self.viewModel.remain, gasLimit: self.viewModel.gasLimit)
    } else {
      self.delegate?.approveTokenViewControllerDidApproved(self, address: self.viewModel.address, remain: self.viewModel.remain, state: self.viewModel.state, toAddress: self.viewModel.toAddress, gasLimit: self.viewModel.gasLimit)
    }
    self.dismiss(animated: true, completion: {
      
    })
  }

  @IBAction func editButtonTapped(_ sender: Any) {
    
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func coordinatorDidUpdateGasLimit(_ gas: BigInt) {
    self.viewModel.gasLimit = gas
    guard self.isViewLoaded else { return }
    self.gasFeeLabel.text = self.viewModel.getFeeString()
    self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
  }
}

extension ApproveTokenViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 380
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
