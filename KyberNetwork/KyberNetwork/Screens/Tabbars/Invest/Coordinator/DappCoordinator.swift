//
//  DappCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 21/12/2021.
//

import Foundation
import TrustKeystore
import CryptoKit
import Result
import APIKit
import JSONRPCKit
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnectSwift
import BigInt
import WebKit
import KrystalWallets
import AppState


protocol DappCoordinatorDelegate: class {
  func dAppCoordinatorDidSelectAddWallet()
  func dAppCoordinatorDidSelectManageWallet()
  func dAppCoordinatorDidSelectAddChainWallet(chainType: ChainType)
}

class DappCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
  }
  
  lazy var rootViewController: DappBrowserHomeViewController = {
    let controller = DappBrowserHomeViewController()
    controller.delegate = self
    return controller
  }()
  
  private lazy var urlParser: BrowserURLParser = {
      return BrowserURLParser()
  }()
  
  var address: KAddress {
    return AppDelegate.session.address
  }
  
  private var browserViewController: BrowserViewController?
  private var transactionConfirm: DappBrowerTransactionConfirmPopup?
  
  weak var delegate: DappCoordinatorDelegate?
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }
  
  func stop() {
    
  }
  
  fileprivate func openWalletListView() {
    let viewModel = WalletsListViewModel()
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }
  
  func openBrowserScreen(searchText: String) {
    if address.isWatchWallet { return }
    guard let url = urlParser.url(from: searchText.trimmed) else { return }
    let vm = BrowserViewModel(url: url, address: address)
    let vc = BrowserViewController(viewModel: vm)
    vc.delegate = self
    vc.webView.uiDelegate = self
    self.navigationController.pushViewController(vc, animated: true)
    self.browserViewController = vc
  }

  func appCoordinatorDidUpdateChain(isSwitchChain: Bool = true) {
    guard let topVC = self.navigationController.topViewController, topVC is BrowserViewController, let unwrap = self.browserViewController else { return }
    if address.isWatchWallet {
      self.navigationController.popViewController(animated: true, completion: nil)
      return
    }
    if isSwitchChain {
      Tracker.track(event: .dappSwitchChain, customAttributes: ["url": unwrap.viewModel.url, "chainId": KNGeneralProvider.shared.customRPC.chainID, "title": unwrap.viewModel.url.absoluteString])
    } else {
      Tracker.track(event: .dappSwitchWallet, customAttributes: ["url": unwrap.viewModel.url, "chainId": KNGeneralProvider.shared.customRPC.chainID, "title": unwrap.viewModel.url.absoluteString])
    }
    
    let url = unwrap.viewModel.url
    self.navigationController.popViewController(animated: false) {
      let vm = BrowserViewModel(url: url, address: self.address)
      let vc = BrowserViewController(viewModel: vm)
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: false)
      self.browserViewController = vc
    }
  }

  func appCoordinatorSwitchAddress() {
    self.appCoordinatorDidUpdateChain(isSwitchChain: false)
  }

  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if let trans = self.transactionStatusVC?.transaction, trans.hash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
}

extension DappCoordinator: DappBrowserHomeViewControllerDelegate {
  func dappBrowserHomeViewController(_ controller: DappBrowserHomeViewController, run event: DappBrowserHomeEvent) {
    switch event {
    case .enterText(let text):
      self.openBrowserScreen(searchText: text)
    case .showAllRecently:
      let viewModel = RecentlyHistoryViewModel { item in
        self.openBrowserScreen(searchText: item.url)
      }
      let controller = RecentlyHistoryViewController(viewModel: viewModel)
      self.navigationController.pushViewController(controller, animated: true, completion: nil)
    }
  }
}

extension DappCoordinator: BrowserViewControllerDelegate {
  func browserViewController(_ controller: BrowserViewController, run event: BrowserViewEvent) {
    switch event {
    case .openOption(let url):
      let controller = BrowserOptionsViewController(
        url: url,
        canGoBack: controller.webView.canGoBack,
        canGoForward: controller.webView.canGoForward
      )
      controller.delegate = self
      self.navigationController.present(controller, animated: true, completion: nil)
    case .switchChain:
      break
    case .addChainWallet(let chainType):
      delegate?.dAppCoordinatorDidSelectAddChainWallet(chainType: chainType)
    }
  }
  
  func didCall(action: DappAction, callbackID: Int, inBrowserViewController viewController: BrowserViewController) {
    let url = viewController.viewModel.url.absoluteString
    func rejectDappAction() {
      viewController.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
      navigationController.topViewController?.displayError(error: InCoordinatorError.onlyWatchAccount)
    }

    func performDappAction(address: KAddress) {
      switch action {
      case .signTransaction(let unconfirmedTransaction):
        print(unconfirmedTransaction)
        self.executeTransaction(action: action, callbackID: callbackID, tx: unconfirmedTransaction, url: url)
      case .sendTransaction(let unconfirmedTransaction):
        print(unconfirmedTransaction)
        self.executeTransaction(action: action, callbackID: callbackID, tx: unconfirmedTransaction, url: url)
      case .signMessage(let hexMessage):
        let vm = SignMessageConfirmViewModel(
          url: url,
          address: address.addressString,
          message: hexMessage,
          onConfirm: {
            self.signMessage(with: .message(hexMessage.toHexData), callbackID: callbackID)
          },
          onCancel: {
            let error = DAppError.cancelled
            self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
          }
        )
        let vc = SignMessageConfirmPopup(viewModel: vm)
        self.navigationController.present(vc, animated: true, completion: nil)
      case .signPersonalMessage(let hexMessage):
        let vm = SignMessageConfirmViewModel(
          url: url,
          address: address.addressString,
          message: hexMessage,
          onConfirm: {
            self.signMessage(with: .personalMessage(hexMessage.toHexData), callbackID: callbackID)
          },
          onCancel: {
            let error = DAppError.cancelled
            self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
          }
        )
        let vc = SignMessageConfirmPopup(viewModel: vm)
        self.navigationController.present(vc, animated: true, completion: nil)
      case .signTypedMessage(let typedData):
        let vm = SignMessageConfirmViewModel(
          url: url,
          address: address.addressString,
          message: typedData.first?.value.string ?? "0x",
          onConfirm: {
            self.signMessage(with: .typedMessage(typedData), callbackID: callbackID)
          },
          onCancel: {
            let error = DAppError.cancelled
            self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
          }
        )
        let vc = SignMessageConfirmPopup(viewModel: vm)
        self.navigationController.present(vc, animated: true, completion: nil)
      case .signTypedMessageV3(let typedData):
        let vm = SignMessageConfirmViewModel(
          url: url,
          address: address.addressString,
          message: typedData.message["functionSignature"]?.stringValue ?? "0x",
          onConfirm: {
            self.signMessage(with: .eip712v3And4(typedData), callbackID: callbackID)
          },
          onCancel: {
            let error = DAppError.cancelled
            self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
          }
        )
        let vc = SignMessageConfirmPopup(viewModel: vm)
        self.navigationController.present(vc, animated: true, completion: nil)
      case .ethCall(from: let from, to: let to, data: let data):
        let callRequest = CallRequest(to: to, data: data)
        let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let output):
                let callback = DappCallback(id: callbackID, value: .ethCall(output))
                self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))
              case .failure(let error):
                if case let SessionTaskError.responseError(JSONRPCError.responseError(_, message: message, _)) = error {
                  self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(.nodeError(message)))
                } else {
                  self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(.cancelled))
                }
              }
            }
          }
        }
      case .walletAddEthereumChain(let customChain):
        guard let targetChainId = Int(chainId0xString: customChain.chainId), let chainType = ChainType.make(chainID: targetChainId) else {
          let error = DAppError.nodeError("Invaild chain ID")
          self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
          return
        }
        if KNGeneralProvider.shared.customRPC.chainID == targetChainId {
          let callback = DappCallback(id: callbackID, value: .walletSwitchEthereumChain)
          self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))
        } else {
          let alertController = KNPrettyAlertController(
            title: "",
            message: "Please switch to \(chainType.chainName()) to continue".toBeLocalised(),
            secondButtonTitle: Strings.ok,
            firstButtonTitle: Strings.cancel,
            secondButtonAction: {
              AppState.shared.updateChain(chain: chainType)
//              KNGeneralProvider.shared.currentChain = chainType
//              KNNotificationUtil.postNotification(for: kChangeChainNotificationKey)
            },
            firstButtonAction: {
              let error = DAppError.cancelled
              self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
            }
          )
          alertController.popupHeight = 220
          self.navigationController.present(alertController, animated: true, completion: nil)
        }
      case .walletSwitchEthereumChain(let targetChain):
        guard let targetChainId = Int(chainId0xString: targetChain.chainId), let chainType = ChainType.make(chainID: targetChainId) else {
          let error = DAppError.nodeError("Invaild chain ID")
          self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
          return
        }
        if KNGeneralProvider.shared.customRPC.chainID == targetChainId {
          let callback = DappCallback(id: callbackID, value: .walletSwitchEthereumChain)
          self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))
        } else {
          let alertController = KNPrettyAlertController(
            title: "",
            message: "Please switch to \(chainType.chainName()) to continue".toBeLocalised(),
            secondButtonTitle: Strings.ok,
            firstButtonTitle: Strings.cancel,
            secondButtonAction: {
              AppState.shared.updateChain(chain: chainType)
              KNNotificationUtil.postNotification(for: kChangeChainNotificationKey)
            },
            firstButtonAction: {
              let error = DAppError.cancelled
              self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(error))
            }
          )
          alertController.popupHeight = 220
          self.navigationController.present(alertController, animated: true, completion: nil)
        }
      default:
        self.navigationController.showTopBannerView(message: "This dApp action is not supported yet")
      }
    }
    
    switch self.address.addressType {
    case .evm:
      if self.address.isWatchWallet {
        switch action {
        case .signTransaction, .sendTransaction, .signMessage, .signPersonalMessage, .signTypedMessage, .signTypedMessageV3, .ethCall, .unknown, .sendRawTransaction:
            return rejectDappAction()
        case .walletAddEthereumChain, .walletSwitchEthereumChain:
          return performDappAction(address: self.address)
        }
      } else {
        return performDappAction(address: self.address)
      }
    case .solana:
      break
    }
  }

  private func executeTransaction(action: DappAction, callbackID: Int, tx: SignTransactionObject, url: String) {
    self.askToAsyncSign(action: action, callbackID: callbackID, tx: tx, message: "Prepare to send your transaction", url: url) {
    }
  }

  private func signMessage(with type: SignMessageType, callbackID: Int) {
    if address.isWatchWallet {
      return
    }
    let signer = EthSigner()
    var result: Result<Data, Error>
    do {
      switch type {
      case .message(let data):
        let signedData = try signer.signMessageHash(address: address, data: data, addPrefix: false)
        result = .success(signedData)
      case .personalMessage(let data):
        let signedData = try signer.signMessageHash(address: address, data: data, addPrefix: true)
        result = .success(signedData)
      case .typedMessage(let typedData):
        if typedData.isEmpty {
          result = .failure(WalletManagerError.failedToSignMessage)
        } else {
          let schemas = typedData.map { $0.schemaData }.reduce(Data(), { $0 + $1 }).sha3(.keccak256)
          let values = typedData.map { $0.typedData }.reduce(Data(), { $0 + $1 }).sha3(.keccak256)
          let combined = (schemas + values).sha3(.keccak256)
          let signedData = try signer.signMessageHash(address: address, data: combined, addPrefix: false)
          result = .success(signedData)
        }
      case .eip712v3And4(let data):
        let signedData = try signer.signEip712Data(address: address, data: data.digest)
        result = .success(signedData)
      }
    } catch {
      result = .failure(error)
    }
    
    var callback: DappCallback
    switch result {
    case .success(let data):
      callback = DappCallback(id: callbackID, value: .signMessage(data))
      self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))
    case .failure:
      self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
    }
  }
  
  func askToAsyncSign(action: DappAction, callbackID: Int, tx: SignTransactionObject, message: String, url: String, sign: @escaping () -> Void) {
    if address.isWatchWallet {
      return
    }
    let onSign = { (setting: ConfirmAdvancedSetting) in
      print("[Debug] \(setting)")
      self.navigationController.displayLoading()
      self.getLatestNonce { nonce in
        var sendTx = tx
        sendTx.updateNonce(nonce: nonce)
        print("[Dapp] raw tx \(tx)")
        if KNGeneralProvider.shared.isUseEIP1559 {
          let eipTx = sendTx.toEIP1559Transaction(setting: setting)
          KNGeneralProvider.shared.getEstimateGasLimit(eip1559Tx: eipTx) { (estResult) in
            switch estResult {
            case .success:
              if let data = EIP1559TransactionSigner().signTransaction(address: self.address, eip1559Tx: eipTx) {
                KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
                  switch sendResult {
                  case .success(let hash):
                    print("[Dapp] hash \(hash)")
                    let data = Data(_hex: hash)
                    let callback = DappCallback(id: callbackID, value: .sentTransaction(data))
                    self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))

                    let historyTransaction = InternalHistoryTransaction(
                      type: .contractInteraction,
                      state: .pending,
                      fromSymbol: nil,
                      toSymbol: nil,
                      transactionDescription: Strings.application,
                      transactionDetailDescription: tx.to ?? "",
                      transactionObj: nil,
                      eip1559Tx: eipTx
                    )
                    historyTransaction.hash = hash
                    historyTransaction.time = Date()
                    historyTransaction.nonce = nonce
                    EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                    self.openTransactionStatusPopUp(transaction: historyTransaction)
                  case .failure(let error):
                    self.navigationController.displayError(error: error)
                  }
                  self.navigationController.hideLoading()
                })
              }
            case .failure(let error):
              self.navigationController.hideLoading()
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
              self.navigationController.showErrorTopBannerMessage(message: errorMessage)
            }
          }
        } else {
          let signTx = sendTx.toSignTransaction(address: self.address.addressString, setting: setting)
          KNGeneralProvider.shared.getEstimateGasLimit(transaction: signTx) { estResult in
            switch estResult {
            case .success:
              let signResult = EthereumTransactionSigner().signTransaction(address: self.address, transaction: signTx)
              switch signResult {
              case .success(let signedData):
                KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
                  self.navigationController.hideLoading()
                  switch sendResult {
                  case .success(let hash):
                    let data = Data(_hex: hash)
                    let callback = DappCallback(id: callbackID, value: .sentTransaction(data))
                    self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))

                    let historyTransaction = InternalHistoryTransaction(
                      type: .contractInteraction,
                      state: .pending,
                      fromSymbol: nil,
                      toSymbol: nil,
                      transactionDescription: Strings.application,
                      transactionDetailDescription: tx.to ?? "",
                      transactionObj: sendTx,
                      eip1559Tx: nil
                    )
                    historyTransaction.hash = hash
                    historyTransaction.time = Date()
                    historyTransaction.nonce = nonce
                    EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                    self.openTransactionStatusPopUp(transaction: historyTransaction)
                  case .failure(let error):
                    self.navigationController.displayError(error: error)
                  }
                })
              case .failure(let error):
                self.navigationController.displayError(error: error)
              }
            case .failure(let error):
              self.navigationController.hideLoading()
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
              self.navigationController.showErrorTopBannerMessage(message: errorMessage)
            }
          }
        }
      }
    }
    let onCancel = {
      print("[Dapp] cancel")
      self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
    }
    
    let onChangeGasFee = { (gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) in
      let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: false, gasLimit: gasLimit, selectType: selectType, isContainSlippageSection: false)
      viewModel.baseGasLimit = baseGasLimit
      viewModel.updateGasPrices(
        fast: KNGasCoordinator.shared.fastKNGas,
        medium: KNGasCoordinator.shared.standardKNGas,
        slow: KNGasCoordinator.shared.lowKNGas,
        superFast: KNGasCoordinator.shared.superFastKNGas
      )
      viewModel.advancedGasLimit = advancedGasLimit
      viewModel.advancedMaxPriorityFee = advancedPriorityFee
      viewModel.advancedMaxFee = advancedMaxFee
      viewModel.advancedNonce = advancedNonce
      let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
      vc.delegate = self

      self.getLatestNonce { nonce in
        vc.coordinatorDidUpdateCurrentNonce(nonce)
      }

      self.transactionConfirm?.present(vc, animated: true, completion: nil)

    }
    
    let vm = DappBrowerTransactionConfirmViewModel(transaction: tx, url: url, onSign: onSign, onCancel: onCancel, onChangeGasFee: onChangeGasFee)
    let controller = DappBrowerTransactionConfirmPopup(viewModel: vm)
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionConfirm = controller
  }

  func getLatestNonce(completion: @escaping (Int) -> Void) {
    let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
    web3Service.getTransactionCount(for: address.addressString) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let res):
        completion(res)
      case .failure:
        self.getLatestNonce(completion: completion)
      }
    }
  }
  
  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
}

extension DappCoordinator: BrowserOptionsViewControllerDelegate {
  func browserOptionsViewController(_ controller: BrowserOptionsViewController, run event: BrowserOptionsViewEvent) {
    switch event {
    case .back:
      self.browserViewController?.coodinatorDidReceiveBackEvent()
    case .forward:
      self.browserViewController?.coodinatorDidReceiveForwardEvent()
    case .refresh:
      self.browserViewController?.coodinatorDidReceiveRefreshEvent()
    case .share:
      self.browserViewController?.coodinatorDidReceiveShareEvent()
    case .copy:
      self.browserViewController?.coodinatorDidReceiveCopyEvent()
    case .favourite:
      self.browserViewController?.coodinatorDidReceiveFavoriteEvent()
    case .switchWallet:
      self.openWalletListView()
      self.browserViewController?.coodinatorDidReceiveSwitchWalletEvent()
    }
  }
}

extension DappCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.dAppCoordinatorDidSelectManageWallet()
    case .didSelect(let address):
      return
    case .addWallet:
      self.delegate?.dAppCoordinatorDidSelectAddWallet()
    }
  }
}

extension DappCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let url = WCURL(result) else {
        self.navigationController.showTopBannerView(
          with: Strings.invalidSession,
          message: Strings.invalidSessionTryOtherQR,
          time: 1.5
        )
        return
      }
      
      do {
        let privateKey = try WalletManager.shared.exportPrivateKey(address: AppDelegate.session.address)
        DispatchQueue.main.async {
          let controller = KNWalletConnectViewController(
            wcURL: url,
            pk: privateKey
          )
          self.navigationController.present(controller, animated: true, completion: nil)
        }
      } catch {
        self.navigationController.showTopBannerView(
          with: Strings.privateKeyError,
          message: Strings.canNotGetPrivateKey,
          time: 1.5
        )
      }
    }
  }
}

extension DappCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      self.transactionConfirm?.coordinatorDidUpdateGasPriceType(type, value: value)
    case .helpPressed(let tag):
      var message = "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised()
      switch tag {
      case 1:
        message = "gas.limit.help".toBeLocalised()
      case 2:
        message = "max.priority.fee.help".toBeLocalised()
      case 3:
        message = "max.fee.help".toBeLocalised()
      default:
        break
      }
      self.navigationController.showBottomBannerView(
        message: message,
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .updateAdvancedSetting(gasLimit: let gasLimit, maxPriorityFee: let maxPriorityFee, maxFee: let maxFee):
      self.transactionConfirm?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
    case .updateAdvancedNonce(nonce: let nonce):
      self.transactionConfirm?.coordinatorDidUpdateAdvancedNonce(nonce)
    case .speedupTransactionSuccessfully(let speedupTransaction):
      self.openTransactionStatusPopUp(transaction: speedupTransaction)
    case .cancelTransactionSuccessfully(let cancelTransaction):
      self.openTransactionStatusPopUp(transaction: cancelTransaction)
    case .speedupTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    case .cancelTransactionFailure(let message):
      self.navigationController.showTopBannerView(message: message)
    default:
      break
    }
  }
}

extension DappCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    self.transactionStatusVC = nil
    switch action {
//    case .transfer:
//      self.openSendTokenView()
    case .openLink(let url):
      self.navigationController.openSafari(with: url)
    case .speedUp(let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .goToSupport:
      self.navigationController.openSafari(with: "https://docs.krystal.app/")
    default:
      break
    }
  }

  fileprivate func openTransactionSpeedUpViewController(transaction: InternalHistoryTransaction) {
    let gasLimit: BigInt = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return BigInt(transaction.eip1559Transaction?.reservedGasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
      } else {
        return BigInt(transaction.transactionObject?.reservedGasLimit ?? "") ?? BigInt(0)
      }
    }()
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    
    viewModel.transaction = transaction
    viewModel.isSpeedupMode = true
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.navigationController.present(vc, animated: true, completion: nil)
  }

  fileprivate func openTransactionCancelConfirmPopUpFor(transaction: InternalHistoryTransaction) {
    let gasLimit: BigInt = {
      if KNGeneralProvider.shared.isUseEIP1559 {
        return BigInt(transaction.eip1559Transaction?.reservedGasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
      } else {
        return BigInt(transaction.transactionObject?.reservedGasLimit ?? "") ?? BigInt(0)
      }
    }()
    
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    
    viewModel.isCancelMode = true
    viewModel.transaction = transaction
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.navigationController.present(vc, animated: true, completion: nil)
  }
}

extension DappCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
          browserViewController?.webView.load(navigationAction.request)
        }
        return nil
    }
}
