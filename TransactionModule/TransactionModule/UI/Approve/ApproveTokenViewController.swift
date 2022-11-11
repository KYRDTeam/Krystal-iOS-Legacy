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
import BaseWallet
import Utilities
import Services

public class ApproveTokenViewModel {
  var showEditSettingButton: Bool = false
  var gasLimit: BigInt = AppDependencies.gasConfig.defaultApproveGasLimit
  var value: BigInt = TransactionConstants.maxTokenAmount
  var headerTitle: String = "Approve Token"
  var chain: ChainType
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
    return "\(NumberFormatUtils.gasFeeFormat(number: fee)) \(chain.quoteToken())"
  }

  func getFeeUSDString() -> String {
    let quoteUSD = AppDependencies.priceStorage.getQuoteUsdRate(chain: chain) ?? 0
    let feeUSD = self.getFee() * BigInt(quoteUSD * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String =  feeUSD.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
    return "(~ \(valueString) USD)"
  }

  public init(symbol: String, tokenAddress: String, remain: BigInt, toAddress: String, chain: ChainType) {
    self.symbol = symbol
    self.tokenAddress = tokenAddress
    self.remain = remain
    self.toAddress = toAddress
    self.chain = chain
  }
  
  func getGasPrice(chain: ChainType, setting: TxSettingObject) -> BigInt {
      if let basic = setting.basic {
          switch basic.gasType {
          case .slow:
              return AppDependencies.gasConfig.getLowGasPrice(chain: chain)
          case .regular:
              return AppDependencies.gasConfig.getStandardGasPrice(chain: chain)
          case .fast:
              return AppDependencies.gasConfig.getFastGasPrice(chain: chain)
          case .superFast:
              return AppDependencies.gasConfig.getSuperFastGasPrice(chain: chain)
          }
      } else {
          return setting.advanced?.maxFee ?? .zero
      }
  }
  
  func sendApproveRequest(value: BigInt, onCompleted: @escaping (Error?) -> Void) {
    let service = EthereumNodeService(chain: chain)
    let gasPrice = self.getGasPrice(chain: chain, setting: setting)
    service.getSendApproveERC20TokenEncodeData(spender: toAddress, value: value) { [weak self] result in
        guard let self = self else { return }
        switch result {
        case .success(let hex):
            self.getLatestNonce { nonce in
              guard let nonce = nonce else {
                return
              }
              let legacyTx = LegacyTransaction(
                  value: BigInt(0),
                  address: AppState.shared.currentAddress.addressString,
                  to: self.tokenAddress,
                  nonce: nonce,
                  data: hex,
                  gasPrice: gasPrice,
                  gasLimit: self.setting.gasLimit,
                  chainID: self.chain.getChainId()
              )
              let signResult = EthereumTransactionSigner().signTransaction(address: AppState.shared.currentAddress, transaction: legacyTx)
              switch signResult {
              case .success(let signedData):
                  TransactionManager.txProcessor.sendTxToNode(data: signedData, chain: self.chain) { result in
                      switch result {
                      case .success(let hash):
                          print(hash)
                          onCompleted(nil)
                          let pendingTx = ApprovePendingTxInfo(
                              legacyTx: legacyTx,
                              eip1559Tx: nil,
                              chain: self.chain,
                              date: Date(),
                              hash: hash,
                              nonce: legacyTx.nonce,
                              walletAddress: AppState.shared.currentAddress.addressString,
                              contractAddress: self.toAddress
                          )
                          TransactionManager.txProcessor.savePendingTx(txInfo: pendingTx)
                      case .failure(let error):
                          onCompleted(error)
                      }
                  }
              case .failure(let error):
                  onCompleted(error)
              }
              
            }
        case .failure(let error):
            onCompleted(error)
        }
    }
  }
  
  func getLatestNonce(completion: @escaping (Int?) -> Void) {
      let address = AppState.shared.currentAddress.addressString
      let web3Client = EthereumNodeService(chain: AppState.shared.currentChain)
      web3Client.getTransactionCount(address: address) { result in
          switch result {
          case .success(let nonce):
              AppDependencies.nonceStorage.updateNonce(chain: AppState.shared.currentChain, address: address, value: nonce)
              completion(nonce)
          default:
              completion(nil)
          }
      }
  }
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
  public var onSuccessApprove: (() -> Void)? = nil
  public var onFailApprove: (() -> Void)? = nil
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
    if !self.viewModel.showEditSettingButton {
      self.editIcon.isHidden = true
      self.editLabel.isHidden = true
      self.editButton.isHidden = true
    }
    self.headerTitle.text = self.viewModel.headerTitle
  }
  
  func setupChainInfo() {
    chainIcon.image = viewModel.chain.squareIcon()
    chainLabel.text = viewModel.chain.chainName()
  }

  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    if viewModel.remain.isZero {
      sendApprove()
    } else {
      resetAllowanceBeforeSend()
    }
  }
  
  func sendApprove() {
    self.viewModel.sendApproveRequest(value: TransactionConstants.maxTokenAmount) { error in
      self.dismiss(animated: true)
      if error != nil {
        if let onFailApprove = self.onFailApprove {
          onFailApprove()
        }
      } else {
        if let onSuccessApprove = self.onSuccessApprove {
          onSuccessApprove()
        }
      }
    }
  }
  
  func resetAllowanceBeforeSend() {
    self.viewModel.sendApproveRequest(value: BigInt(0)) { error in
      if error != nil {
        self.sendApprove()
      } else {
        //TODO: Show error here
      }
    }
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
