//
//  ApproveTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/25/20.
//

import UIKit
import BigInt
import AppState
import Dependencies
import BaseModule
import Utilities

//protocol ApproveTokenViewModel {
//  func getFee() -> BigInt
//  func getFeeString() -> String
//  func getFeeUSDString() -> String
//  var subTitleText: String { get }
//  var remain: BigInt { get }
//  var state: Bool { get }
//  var symbol: String { get }
//  var toAddress: String { get }
//  var tokenAddress: String { get }
//  var gasLimit: BigInt { get set }
//  var value: BigInt { get set }
//
//  var showEditSettingButton: Bool { get set }
//  var gasPrice: BigInt { get set }
//  var headerTitle: String { get set }
//}

public class ApproveTokenViewModel {
  var showEditSettingButton: Bool = false
  var gasLimit: BigInt = AppDependencies.gasConfig.defaultApproveGasLimit
  var value: BigInt = BigInt(2).power(256) - BigInt(1)
  var headerTitle: String = "Approve Token"
  
  var tokenAddress: String
  let remain: BigInt
  var gasPrice: BigInt = AppDependencies.gasConfig.getStandardGasPrice(chain: AppState.shared.currentChain)
  var toAddress: String
  
  var subTitleText: String {
    return String(format: "You need to approve Krystal to spend %@", self.symbol.uppercased())
  }
  var state: Bool {
    return false
  }
  var symbol: String
  var setting: TxSettingObject = .default
  
  
  func getFee() -> BigInt {
    let fee = self.gasPrice * self.gasLimit
    return fee
  }

  func getFeeString() -> String {
    let fee = self.getFee()
    return "\(NumberFormatUtils.gasFeeFormat(number: fee)) \(AppState.shared.currentChain.quoteToken())"
  }

  func getFeeUSDString() -> String {
    let quoteUSD = AppDependencies.priceStorage.getQuoteUsdRate(chain: AppState.shared.currentChain) ?? 0
    let feeUSD = self.getFee() * BigInt(quoteUSD * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String =  feeUSD.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return "(~ \(valueString) USD)"
  }

  public init(symbol: String, tokenAddress: String, remain: BigInt, toAddress: String) {
    self.symbol = symbol
    self.tokenAddress = tokenAddress
    self.remain = remain
    self.toAddress = toAddress
  }
}

protocol ApproveTokenViewControllerDelegate: class {
//  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, token: TokenObject, remain: BigInt, gasLimit: BigInt)
//  func approveTokenViewControllerDidApproved(_ controller: ApproveTokenViewController, address: String, remain: BigInt, state: Bool, toAddress: String?, gasLimit: BigInt)
//  func approveTokenViewControllerGetEstimateGas(_ controller: ApproveTokenViewController, tokenAddress: String, value: BigInt)
}

public class ApproveTokenViewController: KNBaseViewController {
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
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainLabel: UILabel!
  
  var viewModel: ApproveTokenViewModel
  let transitor = TransitionDelegate()
  weak var delegate: ApproveTokenViewControllerDelegate?
  
  var approveValue: BigInt {
    return self.viewModel.value
  }
  
  var selectedGasPrice: BigInt {
    return self.viewModel.gasPrice
  }

  public init(viewModel: ApproveTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: "ApproveTokenViewController", bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    self.setupChainInfo()
    self.gasFeeLabel.text = self.viewModel.getFeeString()
    self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
    self.cancelButton.rounded(radius: 16)
    self.confirmButton.rounded(radius: 16)
    self.descriptionLabel.text = self.viewModel.subTitleText
    self.contractAddressLabel.text = self.viewModel.toAddress
    
//    if let tokenAddress = self.viewModel.tokenAddress {
//      self.delegate?.approveTokenViewControllerGetEstimateGas(self, tokenAddress: tokenAddress, value: self.viewModel.value)
//    }
    
    if !self.viewModel.showEditSettingButton {
      self.editIcon.isHidden = true
      self.editLabel.isHidden = true
      self.editButton.isHidden = true
    }
    self.headerTitle.text = self.viewModel.headerTitle
  }
  
  func setupChainInfo() {
    chainIcon.image = AppState.shared.currentChain.squareIcon()
    chainLabel.text = AppState.shared.currentChain.chainName()
  }

  @IBAction func confirmButtonTapped(_ sender: UIButton) {
//    let ethBalance = KNGeneralProvider.shared.quoteTokenObject.getBalanceBigInt()
//    guard self.viewModel.getFee() < ethBalance else {
//      self.showWarningTopBannerMessage(
//        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
//        message: String(format: Strings.insufficientTokenForNetworkFee, KNGeneralProvider.shared.quoteTokenObject.symbol)
//      )
//      return
//    }
//    if let token = self.viewModel.token {
//      self.delegate?.approveTokenViewControllerDidApproved(self, token: token, remain: self.viewModel.remain, gasLimit: self.viewModel.gasLimit)
//    } else {
//      self.delegate?.approveTokenViewControllerDidApproved(self, address: self.viewModel.address, remain: self.viewModel.remain, state: self.viewModel.state, toAddress: self.viewModel.toAddress, gasLimit: self.viewModel.gasLimit)
//    }
//    self.dismiss(animated: true, completion: {
//
//    })
  }

  @IBAction func editButtonTapped(_ sender: Any) {
//    TransactionSettingPopup.show(on: self, chain: chain, currentSetting: viewModel.setting, onConfirmed: { [weak self] settingObject in
//        self?.viewModel.setting = settingObject
//        self?.reloadGasUI()
//    }, onCancelled: {
//        return
//    })
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  fileprivate func updateGasFeeUI() {
    self.gasFeeLabel.text = self.viewModel.getFeeString()
    self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
  }
  
  func coordinatorDidUpdateGasLimit(_ gas: BigInt) {
    self.viewModel.gasLimit = gas
    guard self.isViewLoaded else { return }
    updateGasFeeUI()
  }
}

extension ApproveTokenViewController: BottomPopUpAbstract {
  public func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  public func getPopupHeight() -> CGFloat {
    return 380
  }

  public func getPopupContentView() -> UIView {
    return self.contentView
  }
}
