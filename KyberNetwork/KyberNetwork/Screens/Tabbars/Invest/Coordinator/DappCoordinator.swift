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

class DappCoordinator: Coordinator {
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
  
  private var browserViewController: BrowserViewController?
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }
  
  func stop() {
    
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
}

extension DappCoordinator: DappBrowserHomeViewControllerDelegate {
  func dappBrowserHomeViewController(_ controller: DappBrowserHomeViewController, run event: DappBrowserHomeEvent) {
    switch event {
    case .enterText(let text):
      self.openBrowserScreen(searchText: text)
    case .showAllRecently:
      let controller = RecentlyHistoryViewController()
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
    func rejectDappAction() {
      viewController.coordinatorNotifyFinish(callbackID: callbackID, value: .failure(DAppError.cancelled))
      navigationController.topViewController?.displayError(error: InCoordinatorError.onlyWatchAccount)
    }
    
    func performDappAction(account: Address) {
      switch action {
      case .signTransaction(let unconfirmedTransaction):
        print(unconfirmedTransaction)
        self.executeTransaction(action: action, callbackID: callbackID, tx: unconfirmedTransaction)
      case .sendTransaction(let unconfirmedTransaction):
        print(unconfirmedTransaction)
        self.executeTransaction(action: action, callbackID: callbackID, tx: unconfirmedTransaction)
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
//      case .walletSwitchEthereumChain(let targetChain):
//        break
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
  
  private func executeTransaction(action: DappAction, callbackID: Int, tx: SignTransactionObject) {
    self.askToAsyncSign(action: action, callbackID: callbackID, tx: tx, message: "Prepare to send your transaction") {
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
  
  func askToAsyncSign(action: DappAction, callbackID: Int, tx: SignTransactionObject, message: String, sign: @escaping () -> Void) {
    guard case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider else {
      return
    }
      let onSign = {
        self.navigationController.displayLoading()
        self.getLatestNonce { nonce in
          var sendTx = tx
          sendTx.updateNonce(nonce: nonce)
          let signTx = sendTx.toSignTransaction(account: account)
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
      let onCancel = {
      }
      DispatchQueue.main.async {
          UIAlertController.showShouldSign(from: self.navigationController,
                                           title: "Request to sign a message",
                                           message: message,
                                           onSign: onSign,
                                           onCancel: onCancel)
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
      self.browserViewController?.coodinatorDidReceiveSwitchWalletEvent()
    }
  }
}
