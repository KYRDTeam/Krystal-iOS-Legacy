//
//  DappCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 21/12/2021.
//

import Foundation
import TrustKeystore
import TrustCore
import CryptoKit
import Result
import APIKit
import JSONRPCKit
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnectSwift
import BigInt

protocol DappCoordinatorDelegate: class {
  func dAppCoordinatorDidSelectAddWallet()
  func dAppCoordinatorDidSelectWallet(_ wallet: Wallet)
  func dAppCoordinatorDidSelectManageWallet()
}

class DappCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  lazy var rootViewController: DappBrowserHomeViewController = {
    let controller = DappBrowserHomeViewController()
    controller.delegate = self
    return controller
  }()
  
  private lazy var urlParser: BrowserURLParser = {
      return BrowserURLParser()
  }()
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
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
    let viewModel = WalletsListViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.currentWallet
    )
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }
  
  func openBrowserScreen(searchText: String) {
    guard case .real(let account) = self.session.wallet.type else { return }
    guard let url = urlParser.url(from: searchText.trimmed) else { return }
    let vm = BrowserViewModel(url: url, account: account)
    let vc = BrowserViewController(viewModel: vm)
    vc.delegate = self
    self.navigationController.pushViewController(vc, animated: true)
    self.browserViewController = vc
  }

  func appCoordinatorDidUpdateChain() {
    guard let topVC = self.navigationController.topViewController, topVC is BrowserViewController, let unwrap = self.browserViewController else { return }
    guard case .real(let account) = self.session.wallet.type else {
      self.navigationController.popViewController(animated: true, completion: nil)
      return
    }
    let url = unwrap.viewModel.url
    self.navigationController.popViewController(animated: false) {
      let vm = BrowserViewModel(url: url, account: account)
      let vc = BrowserViewController(viewModel: vm)
      vc.delegate = self
      self.navigationController.pushViewController(vc, animated: false)
      self.browserViewController = vc
    }
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.appCoordinatorDidUpdateChain()
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
      let controller = BrowserOptionsViewController(url: url)
      controller.delegate = self
      self.navigationController.present(controller, animated: true, completion: nil)
    case .switchChain:
      break
    }
  }
  
  func didCall(action: DappAction, callbackID: Int, inBrowserViewController viewController: BrowserViewController) {
    let url = viewController.viewModel.url.absoluteString
    func rejectDappAction() {
      viewController.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
      navigationController.topViewController?.displayError(error: InCoordinatorError.onlyWatchAccount)
    }
    
    func performDappAction(account: Address) {
      switch action {
      case .signTransaction(let unconfirmedTransaction):
        print(unconfirmedTransaction)
        self.executeTransaction(action: action, callbackID: callbackID, tx: unconfirmedTransaction, url: url)
      case .sendTransaction(let unconfirmedTransaction):
        print(unconfirmedTransaction)
        self.executeTransaction(action: action, callbackID: callbackID, tx: unconfirmedTransaction, url: url)
      case .signMessage(let hexMessage):
        signMessage(with: .message(hexMessage.toHexData), callbackID: callbackID)
      case .signPersonalMessage(let hexMessage):
        signMessage(with: .personalMessage(hexMessage.toHexData), callbackID: callbackID)
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
//      case .walletAddEthereumChain(let customChain):
//        break
      case .walletSwitchEthereumChain(let targetChain):
        break
      default:
        self.navigationController.showTopBannerView(message: "This dApp action is not supported yet")
      }
    }
    
    switch session.wallet.type {
    case .real(let account):
      return performDappAction(account: account.address)
    case .watch(let account):
        switch action {
        case .signTransaction, .sendTransaction, .signMessage, .signPersonalMessage, .signTypedMessage, .signTypedMessageV3, .ethCall, .unknown, .sendRawTransaction:
            return rejectDappAction()
        case .walletAddEthereumChain, .walletSwitchEthereumChain:
          return performDappAction(account: account)
        }
    }
  }
  
  private func executeTransaction(action: DappAction, callbackID: Int, tx: SignTransactionObject, url: String) {
    self.askToAsyncSign(action: action, callbackID: callbackID, tx: tx, message: "Prepare to send your transaction", url: url) {
    }
  }
  
  private func signMessage(with type: SignMessageType, callbackID: Int) {
    guard case .real(let account) = self.session.wallet.type, let keystore = self.session.externalProvider?.keystore else { return }
    var result: Result<Data, KeystoreError>
    switch type {
    case .message(let data):
      result  = keystore.signPersonalMessage(data, for: account)
    case .personalMessage(let data):
      result = keystore.signPersonalMessage(data, for: account)
    }
    var callback: DappCallback
    switch result {
    case .success(let data):
      callback = DappCallback(id: callbackID, value: .signMessage(data))
      self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))
    case .failure(let error):
      self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
    }
  }
  
  func askToAsyncSign(action: DappAction, callbackID: Int, tx: SignTransactionObject, message: String, url: String, sign: @escaping () -> Void) {
    guard case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider else {
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
          print("[Dapp] eip tx \(eipTx)")
          if let data = provider.signContractGenericEIP1559Transaction(eipTx) {
            KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
              switch sendResult {
              case .success(let hash):
                print("[Dapp] hash \(hash)")
                let data = Data(_hex: hash)
                let callback = DappCallback(id: callbackID, value: .sentTransaction(data))
                self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))

                let historyTransaction = InternalHistoryTransaction(type: .contractInteraction, state: .pending, fromSymbol: nil, toSymbol: nil, transactionDescription: "DApp", transactionDetailDescription: "", transactionObj: nil, eip1559Tx: eipTx)
                historyTransaction.hash = hash
                historyTransaction.time = Date()
                historyTransaction.nonce = nonce
                EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                
              case .failure(let error):
                self.navigationController.displayError(error: error)
              }
              self.navigationController.hideLoading()
            })
          }
        } else {
          let signTx = sendTx.toSignTransaction(account: account, setting: setting)
          provider.signTransactionData(from: signTx) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let signedData):
              KNGeneralProvider.shared.sendSignedTransactionData(signedData.0, completion: { sendResult in
                switch sendResult {
                case .success(let hash):
                  let data = Data(_hex: hash)
                  let callback = DappCallback(id: callbackID, value: .sentTransaction(data))
                  self.browserViewController?.coordinatorNotifyFinish(callbackID: callbackID, value: .success(callback))
                  
                  let historyTransaction = InternalHistoryTransaction(type: .contractInteraction, state: .pending, fromSymbol: nil, toSymbol: nil, transactionDescription: "DApp", transactionDetailDescription: "", transactionObj: sendTx, eip1559Tx: nil)
                  historyTransaction.hash = hash
                  historyTransaction.time = Date()
                  historyTransaction.nonce = nonce
                  EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                case .failure(let error):
                  self.navigationController.displayError(error: error)
                }
              })
            case .failure(let error):
              self.navigationController.displayError(error: error)
            }
            self.navigationController.hideLoading()
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
//      self.gasPriceSelector = vc
    }
    
    let vm = DappBrowerTransactionConfirmViewModel(transaction: tx, url: url, onSign: onSign, onCancel: onCancel, onChangeGasFee: onChangeGasFee)
    let controller = DappBrowerTransactionConfirmPopup(viewModel: vm)
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionConfirm = controller
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
    case .copy(let wallet):
      UIPasteboard.general.string = wallet.address
      let hud = MBProgressHUD.showAdded(to: controller.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    case .select(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      self.delegate?.dAppCoordinatorDidSelectWallet(wal)
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
          with: "Invalid session".toBeLocalised(),
          message: "Your session is invalid, please try with another QR code".toBeLocalised(),
          time: 1.5
        )
        return
      }

      if case .real(let account) = self.session.wallet.type {
        let result = self.session.keystore.exportPrivateKey(account: account)
        switch result {
        case .success(let data):
          DispatchQueue.main.async {
            let pkString = data.hexString
            let controller = KNWalletConnectViewController(
              wcURL: url,
              knSession: self.session,
              pk: pkString
            )
            self.navigationController.present(controller, animated: true, completion: nil)
          }
          
        case .failure(_):
          self.navigationController.showTopBannerView(
            with: "Private Key Error",
            message: "Can not get Private key",
            time: 1.5
          )
        }
      }
    }
  }
}

extension DappCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
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
    default:
      break
    }
  }
}
