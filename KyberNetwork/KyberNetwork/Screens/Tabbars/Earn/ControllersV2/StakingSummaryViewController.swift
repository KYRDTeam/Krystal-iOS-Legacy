//
//  StakingSummaryViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 31/10/2022.
//

import UIKit
import KrystalWallets
import BigInt
import AppState
import Result
import APIKit
import JSONRPCKit

protocol StakingSummaryViewControllerDelegate: class {
  func didSendTransaction(viewController: StakingSummaryViewController, internalTransaction: InternalHistoryTransaction)
}

class StakingSummaryViewModel {
  var session: KNSession {
    return AppDelegate.session
  }
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  var gasPrice: BigInt
  var gasLimit: BigInt
  
  let txObject: TxObject
  let settings: UserSettings
  let displayInfo: StakeDisplayInfo
  var transaction: SignTransaction?
  var eip1559Transaction: EIP1559Transaction?
  var shouldDiplayLoading: Observable<Bool> = .init(false)
  var errorMessage: Observable<String> = .init("")
  var internalHistoryTransaction: Observable<InternalHistoryTransaction?> = .init(nil)
  
  init(txObject: TxObject, settings: UserSettings, displayInfo: StakeDisplayInfo) {
    self.txObject = txObject
    self.settings = settings
    self.displayInfo = displayInfo
    self.gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? KNGasConfiguration.earnGasLimitDefault
    if let advanced = settings.1?.maxFee {
      self.gasPrice = advanced
    } else {
      self.gasPrice = settings.0.gasPriceType.getGasValue()
    }
    
    getLatestNonce { nonce in
      self.transaction = txObject.convertToSignTransaction(address: self.currentAddress.addressString, nonce: nonce, settings: settings)
      self.eip1559Transaction = txObject.convertToEIP1559Transaction(address: self.currentAddress.addressString, nonce: nonce, settings: settings)
    }
  }
  
  func getEstimateGasLimit(txEIP1559: EIP1559Transaction?, tx: SignTransaction?) {
    let internalHistory = InternalHistoryTransaction(type: .earn, state: .pending, fromSymbol: self.displayInfo.fromSym, toSymbol: self.displayInfo.toSym, transactionDescription: "\(self.displayInfo.amount) → \(self.displayInfo.receiveAmount)", transactionDetailDescription: "", transactionObj: self.transaction?.toSignTransactionObject(), eip1559Tx: self.eip1559Transaction)
    internalHistory.transactionSuccessDescription = "\(self.displayInfo.amount)) → \(self.displayInfo.receiveAmount)"
    if let txEIP1559 = txEIP1559 {
      shouldDiplayLoading.value = true
      KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: txEIP1559) { (result) in
        DispatchQueue.main.async {
          self.shouldDiplayLoading.value = false
        }
        switch result {
        case .success:
          if let data = EIP1559TransactionSigner().signTransaction(address: self.currentAddress, eip1559Tx: txEIP1559) {
            let nonce = Int(txEIP1559.nonce, radix: 16) ?? 0
            self.sendSignedTransactionDataToNode(data: data, nonce: nonce, internalHistoryTransaction: internalHistory)
          }
          
        case .failure(let error):
          var errorMessage = "Can not estimate Gas Limit"
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
            }
          }
          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
          }
          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
          }
          self.showError(errorMsg: errorMessage)
        }
      }
    } else if let tx = tx {
      shouldDiplayLoading.value = true
      KNGeneralProvider.shared.getEstimateGasLimit(transaction: tx) { (result) in
        DispatchQueue.main.async {
          self.shouldDiplayLoading.value = false
        }
        switch result {
        case .success:
          let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: tx)
          switch signResult {
          case .success(let signedData):
            let nonce = tx.nonce
            self.sendSignedTransactionDataToNode(data: signedData, nonce: nonce, internalHistoryTransaction: internalHistory)
          case .failure:
            self.showError(errorMsg: "Something went wrong, please try again later".toBeLocalised())
          }
        case .failure(let error):
          var errorMessage = "Can not estimate Gas Limit"
          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
            }
          }
          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
          }
          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
          }
          self.showError(errorMsg: errorMessage)
        }
      }
    }
  }
  
  func sendTransaction() {
    if KNGeneralProvider.shared.isUseEIP1559 {
      guard let signTx = eip1559Transaction else { return }
      getEstimateGasLimit(txEIP1559: signTx, tx: nil)
    } else {
      guard let signTx = transaction else { return }
      getEstimateGasLimit(txEIP1559: nil, tx: signTx)
    }
  }
  
  func getLatestNonce(completion: @escaping (Int) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getTransactionCount { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let res):
        completion(res)
      case .failure:
        self.getLatestNonce(completion: completion)
      }
    }
  }
  
  func sendSignedTransactionDataToNode(data: Data, nonce: Int, internalHistoryTransaction: InternalHistoryTransaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    shouldDiplayLoading.value = true
    KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
      DispatchQueue.main.async {
        self.shouldDiplayLoading.value = false
      }
      switch sendResult {
      case .success(let hash):
        provider.minTxCount += 1

        internalHistoryTransaction.hash = hash
        internalHistoryTransaction.nonce = nonce
        internalHistoryTransaction.time = Date()

        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalHistoryTransaction)
        self.openTransactionStatusPopUp(transaction: internalHistoryTransaction)
      case .failure(let error):
        var errorMessage = error.description
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
            errorMessage = message
          }
        }
        self.showError(errorMsg: errorMessage)
      }
    })
  }
  
  func showError(errorMsg: String) {
    errorMessage.value = errorMsg
  }
  
  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    self.internalHistoryTransaction.value = transaction
  }
}

class StakingSummaryViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var containerView: UIView!
  
  @IBOutlet weak var chainIconImageView: UIImageView!
  @IBOutlet weak var chainNameLabel: UILabel!
  
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var platformNameLabel: UILabel!
  
  @IBOutlet weak var apyInfoView: SwapInfoView!
  @IBOutlet weak var receiveAmountInfoView: SwapInfoView!
  @IBOutlet weak var rateInfoView: SwapInfoView!
  @IBOutlet weak var feeInfoView: SwapInfoView!
  weak var delegate: StakingSummaryViewControllerDelegate?
  
  let transitor = TransitionDelegate()
  let viewModel: StakingSummaryViewModel
  
  init(viewModel: StakingSummaryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: StakingSummaryViewController.className, bundle: nil)
    
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    bindingViewModel()
  }
  
  private func setupUI() {
    apyInfoView.setTitle(title: "APY (Est. Yield", underlined: false)
    apyInfoView.iconImageView.isHidden = true
    
    receiveAmountInfoView.setTitle(title: "You will receive", underlined: false)
    receiveAmountInfoView.iconImageView.isHidden = true
    
    rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
    rateInfoView.iconImageView.isHidden = true
    
    feeInfoView.setTitle(title: "Network Fee", underlined: false)
    feeInfoView.iconImageView.isHidden = true
    
    let currentChain = AppState.shared.currentChain
    chainIconImageView.image = currentChain.squareIcon()
    chainNameLabel.text = currentChain.chainName()
    
    apyInfoView.setValue(value: viewModel.displayInfo.apy)
    receiveAmountInfoView.setValue(value: viewModel.displayInfo.receiveAmount)
    rateInfoView.setValue(value: viewModel.displayInfo.rate)
    feeInfoView.setValue(value: viewModel.displayInfo.fee)
    
    tokenIconImageView.setImage(urlString: viewModel.displayInfo.stakeTokenIcon, symbol: "")
    tokenNameLabel.text = viewModel.displayInfo.amount
    platformNameLabel.text = "On " + viewModel.displayInfo.platform.uppercased()
    
    
  }
  
  private func bindingViewModel() {
    viewModel.shouldDiplayLoading.observeAndFire(on: self) { value in
      if value {
        self.displayLoading()
      } else {
        self.hideLoading()
      }
    }
    
    viewModel.errorMessage.observeAndFire(on: self) { value in
      guard !value.isEmpty else { return }
      self.showTopBannerView(message: value)
    }
    
    viewModel.internalHistoryTransaction.observeAndFire(on: self) { value in
      guard let value = value else {
        return
      }
      self.delegate?.didSendTransaction(viewController: self, internalTransaction: value)
    }
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    viewModel.sendTransaction()
  }
  
  @IBAction func tapOutSidePopup(_ sender: UITapGestureRecognizer) {
    dismiss(animated: true)
  }
}

extension StakingSummaryViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 560
    
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
