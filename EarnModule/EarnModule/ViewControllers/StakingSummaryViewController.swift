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
import DesignSystem
import Services
import Dependencies
import TransactionModule
import FittedSheets

//protocol StakingSummaryViewControllerDelegate: class {
//  func didSendTransaction(viewController: StakingSummaryViewController, internalTransaction: InternalHistoryTransaction)
//}

class StakingSummaryViewModel {
    
    var currentAddress: KAddress {
        return AppState.shared.currentAddress
    }
    
    var currentChain: ChainType {
        return AppState.shared.currentChain
    }
    
    //  var gasPrice: BigInt
    var gasLimit: BigInt
    
    let txObject: TxObject
    let setting: TxSettingObject
    let displayInfo: StakeDisplayInfo
    //  var transaction: SignTransaction?
    //  var eip1559Transaction: EIP1559Transaction?
    var shouldDiplayLoading: Observable<Bool> = .init(false)
    var errorMessage: Observable<String> = .init("")
    //  var internalHistoryTransaction: Observable<InternalHistoryTransaction?> = .init(nil)
    var processor: TxProcessorProtocol!
    var service: EthereumNodeService!
    var converter: TxObjectConverter!
    var onSendTxSuccess: (() -> ())?
    
    init(txObject: TxObject, setting: TxSettingObject, displayInfo: StakeDisplayInfo) {
        self.txObject = txObject
        self.setting = setting
        self.displayInfo = displayInfo
        self.gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? Constants.earnGasLimitDefault
        self.service = EthereumNodeService(chain: currentChain)
        self.converter = TxObjectConverter(chain: currentChain)
        //    if let advanced = setting.advanced?.maxFee {
        //      self.gasPrice = advanced
        //    } else {
        //        self.gasPrice = setting.basic?.gasType
        //    }
        //
        //    getLatestNonce { nonce in
        //      self.transaction = txObject.convertToSignTransaction(address: self.currentAddress.addressString, nonce: nonce, settings: settings)
        //      self.eip1559Transaction = txObject.convertToEIP1559Transaction(address: self.currentAddress.addressString, nonce: nonce, settings: settings)
        //    }
    }
    
    //  func getEstimateGasLimit(txEIP1559: EIP1559Transaction?, tx: LegacyTransaction?) {
    //    let internalHistory = InternalHistoryTransaction(type: .earn, state: .pending, fromSymbol: self.displayInfo.fromSym, toSymbol: self.displayInfo.toSym, transactionDescription: "\(self.displayInfo.amount) → \(self.displayInfo.receiveAmount)", transactionDetailDescription: "", transactionObj: self.transaction?.toSignTransactionObject(), eip1559Tx: self.eip1559Transaction)
    //    internalHistory.transactionSuccessDescription = "\(self.displayInfo.amount)) → \(self.displayInfo.receiveAmount)"
    //    if let txEIP1559 = txEIP1559 {
    //      shouldDiplayLoading.value = true
    //      KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: txEIP1559) { (result) in
    //        DispatchQueue.main.async {
    //          self.shouldDiplayLoading.value = false
    //        }
    //        switch result {
    //        case .success:
    //          if let data = EIP1559TransactionSigner().signTransaction(address: self.currentAddress, eip1559Tx: txEIP1559) {
    //            let nonce = Int(txEIP1559.nonce, radix: 16) ?? 0
    //            self.sendSignedTransactionDataToNode(data: data, nonce: nonce, internalHistoryTransaction: internalHistory)
    //          }
    //
    //        case .failure(let error):
    //          var errorMessage = "Can not estimate Gas Limit"
    //          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
    //            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
    //              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
    //            }
    //          }
    //          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
    //            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
    //          }
    //          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
    //            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
    //          }
    //          self.showError(errorMsg: errorMessage)
    //        }
    //      }
    //    } else if let tx = tx {
    //      shouldDiplayLoading.value = true
    //      KNGeneralProvider.shared.getEstimateGasLimit(transaction: tx) { (result) in
    //        DispatchQueue.main.async {
    //          self.shouldDiplayLoading.value = false
    //        }
    //        switch result {
    //        case .success:
    //          let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: tx)
    //          switch signResult {
    //          case .success(let signedData):
    //            let nonce = tx.nonce
    //            self.sendSignedTransactionDataToNode(data: signedData, nonce: nonce, internalHistoryTransaction: internalHistory)
    //          case .failure:
    //            self.showError(errorMsg: "Something went wrong, please try again later".toBeLocalised())
    //          }
    //        case .failure(let error):
    //          var errorMessage = "Can not estimate Gas Limit"
    //          if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
    //            if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
    //              errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
    //            }
    //          }
    //          if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
    //            errorMessage = "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
    //          }
    //          if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
    //            errorMessage = "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
    //          }
    //          self.showError(errorMsg: errorMessage)
    //        }
    //      }
    //    }
    //  }
    
    func sendTransaction() {
        if AppState.shared.currentChain.isSupportedEIP1559() {
            request1559Staking()
        } else {
            requestLegacyStaking()
        }
    }
    
    func request1559Staking() {
        guard let eip1559Tx = converter.convertToEIP1559Transaction(txObject: txObject, address: currentAddress.addressString, setting: setting) else {
            return
        }
        let request = KNEstimateGasLimitRequest(
            from: eip1559Tx.fromAddress,
            to: eip1559Tx.toAddress,
            value: BigInt(eip1559Tx.value.drop0x, radix: 16) ?? BigInt(0),
            data: Data(hexString: eip1559Tx.data) ?? Data(),
            gasPrice: BigInt(eip1559Tx.maxGasFee.drop0x, radix: 16) ?? BigInt(0)
        )
        service.getEstimateGasLimit(request: request, chain: currentChain) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if let signedData = EIP1559TransactionSigner().signTransaction(address: self.currentAddress, eip1559Tx: eip1559Tx) {
                    AppDependencies.txProcessor.sendTxToNode(data: signedData, chain: self.currentChain) { result in
                        switch result {
                        case .success(let hash):
                            self.onSendTxSuccess?()
                        case .failure(let error):
                            self.showError(errorMsg: TxErrorParser.parse(error: error).message)
                        }
                    }
                } else {
                    self.showError(errorMsg: "Something went wrong, please try again later".toBeLocalised())
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                self.showError(errorMsg: txError.message)
            }
        }
    }
    
    func requestLegacyStaking() {
        guard let legacyTx = converter.convertToLegacyTransaction(txObject: txObject, address: currentAddress.addressString, setting: setting) else {
            return
        }
        let request = KNEstimateGasLimitRequest(
            from: legacyTx.address,
            to: legacyTx.to,
            value: legacyTx.value,
            data: legacyTx.data,
            gasPrice: legacyTx.gasPrice
        )
        service.getEstimateGasLimit(request: request, chain: currentChain) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: legacyTx)
                switch signResult {
                case .success(let signedData):
                    AppDependencies.txProcessor.sendTxToNode(data: signedData, chain: self.currentChain) { result in
                        switch result {
                        case .success(let hash):
                            self.onSendTxSuccess?()
                        case .failure(let error):
                            self.showError(errorMsg: TxErrorParser.parse(error: error).message)
                        }
                    }
                case .failure:
                    self.showError(errorMsg: "Something went wrong, please try again later".toBeLocalised())
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                self.showError(errorMsg: txError.message)
            }
        }
    }
    
    func getLatestNonce(completion: @escaping (Int?) -> Void) {
        let address = AppState.shared.currentAddress.addressString
        let web3Client = EthereumNodeService(chain: AppState.shared.currentChain)
        web3Client.getTransactionCount(address: address) { [weak self] result in
            switch result {
            case .success(let nonce):
                AppDependencies.nonceStorage.updateNonce(chain: AppState.shared.currentChain, address: address, value: nonce)
                completion(nonce)
            default:
                completion(nil)
            }
        }
    }
    
    //  func sendSignedTransactionDataToNode(data: Data, nonce: Int, internalHistoryTransaction: InternalHistoryTransaction) {
    //    guard let provider = self.session.externalProvider else {
    //      return
    //    }
    //    shouldDiplayLoading.value = true
    //    KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
    //      DispatchQueue.main.async {
    //        self.shouldDiplayLoading.value = false
    //      }
    //      switch sendResult {
    //      case .success(let hash):
    //        provider.minTxCount += 1
    //
    //        internalHistoryTransaction.hash = hash
    //        internalHistoryTransaction.nonce = nonce
    //        internalHistoryTransaction.time = Date()
    //
    //        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(internalHistoryTransaction)
    //        self.openTransactionStatusPopUp(transaction: internalHistoryTransaction)
    //      case .failure(let error):
    //        var errorMessage = error.description
    //        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
    //          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
    //            errorMessage = message
    //          }
    //        }
    //        self.showError(errorMsg: errorMessage)
    //      }
    //    })
    //  }
    //
    func showError(errorMsg: String) {
        errorMessage.value = errorMsg
    }
    
    //  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    //    self.internalHistoryTransaction.value = transaction
    //  }
    
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
    //  weak var delegate: StakingSummaryViewControllerDelegate?
    
    let viewModel: StakingSummaryViewModel
    
    init(viewModel: StakingSummaryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: StakingSummaryViewController.className, bundle: nil)
        
        self.modalPresentationStyle = .custom
        //    self.transitioningDelegate = transitor
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
        //    apyInfoView.iconImageView.isHidden = true
        
        receiveAmountInfoView.setTitle(title: "You will receive", underlined: false)
        //    receiveAmountInfoView.iconImageView.isHidden = true
        
        rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
        //    rateInfoView.iconImageView.isHidden = true
        
        feeInfoView.setTitle(title: "Network Fee", underlined: false)
        //    feeInfoView.iconImageView.isHidden = true
        
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
        viewModel.onSendTxSuccess = { [weak self] in
            self?.openTxStatusPopup()
        }
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
        
//            viewModel.internalHistoryTransaction.observeAndFire(on: self) { value in
//              guard let value = value else {
//                return
//              }
//              self.delegate?.didSendTransaction(viewController: self, internalTransaction: value)
//            }
    }
    
    func openTxStatusPopup() {
        let popup = StakingTrasactionProcessPopup()
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(420)], options: .init(pullBarHeight: 0))
        dismiss(animated: true) {
            UIApplication.shared.topMostViewController()?.present(sheet, animated: true)
        }
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        viewModel.sendTransaction()
    }
    
    @IBAction func tapOutSidePopup(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
}
