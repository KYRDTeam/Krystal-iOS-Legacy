//
//  MultiSendCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import Foundation
import BigInt
import Result
import TrustCore
//import WalletCore
import Moya
import APIKit
import JSONRPCKit
import QRCodeReaderViewController
import MBProgressHUD
import WalletConnectSwift

class MultiSendCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  
  weak var delegate: KNSendTokenViewCoordinatorDelegate?
  
  lazy var rootViewController: MultiSendViewController = {
    let vm = MultiSendViewModel(wallet: self.session.wallet)
    let controller = MultiSendViewController(viewModel: vm)
    controller.delegate = self
    return controller
  }()
  
  lazy var addContactVC: KNNewContactViewController = {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: "")
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()
  
  fileprivate(set) var searchTokensVC: KNSearchTokenViewController?
  fileprivate(set) var approveVC: MultiSendApproveViewController?
  fileprivate(set) weak var gasPriceSelector: GasFeeSelectorPopupViewController?
  fileprivate(set) var confirmVC: MultiSendConfirmViewController?
  fileprivate(set) var processingTx: TxObject?
  fileprivate(set) var transactionStatusVC: KNTransactionStatusPopUp?
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }
  
  var approvingItems: [MultiSendItem] = []
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }

  func start() {
    guard self.navigationController.viewControllers.last != self.rootViewController else { return }
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
  }
  
  func stop() {
    
  }
  
  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if tx.state == .done, tx.type == .allowance {
      let approveName = String(tx.transactionDescription.dropFirst(8))
      if let found = self.approvingItems.first(where: { element in
        return approveName == element.2.name
      }) {
        self.approveVC?.coordinatorDidUpdateApprove(found)
      }
    }
    //TODO: handle tx hash here
    if let trans = self.transactionStatusVC?.transaction, trans.hash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
  
  func appCoordinatorDidUpdateChain() {
    self.rootViewController.coordinatorDidUpdateChain()
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: self.session.wallet)
  }

  func coordinatorDidUpdatePendingTx() {
    self.rootViewController.coordinatorDidUpdatePendingTx()
  }
}

extension MultiSendCoordinator: MultiSendViewControllerDelegate {
  func multiSendViewController(_ controller: MultiSendViewController, run event: MultiSendViewControllerEvent) {
    switch event {
    case .searchToken(let selectedToken):
      self.openSearchToken(selectedToken: selectedToken.toObject())
    case .openContactsList:
      self.openListContactsView()
    case .addContact(address: let address):
      self.openNewContact(address: address, ens: nil)
    case .checkApproval(items: let items):
      self.navigationController.displayLoading()
      self.requestBuildTx(items: items) { object in
        self.processingTx = object
        self.checkAllowance(contractAddress: object.to, items: items) { remaining in
          if remaining.isEmpty {
            self.rootViewController.coordinatorDidFinishApproveTokens()
          } else {
            self.openApproveView(items: remaining)
          }
          self.navigationController.hideLoading()
        }
      }
    case .confirm(items: let items):
      self.navigationController.displayLoading()
      self.getLatestNonce { result in
        switch result {
        case .success(let nonce):
          let nonceStr = BigInt(nonce).hexEncoded.hexSigned2Complement
          self.processingTx?.nonce = nonceStr
          if let tx = self.processingTx, let gasLimit = BigInt(tx.gasLimit.drop0x, radix: 16), !gasLimit.isZero {
            self.navigationController.hideLoading()
            self.openConfirmView(items: items, txObject: tx)
          } else {
            self.requestBuildTx(items: items) { object in
              self.processingTx = object
              self.navigationController.hideLoading()
              self.openConfirmView(items: items, txObject: object)
            }
          }
        case .failure(let error):
          self.navigationController.hideLoading()
          self.navigationController.showErrorTopBannerMessage(message: error.description)
        }
        
      }
    case .openHistory:
      self.delegate?.sendTokenViewCoordinatorSelectOpenHistoryList()
    case .openWalletsList:
      let viewModel = WalletsListViewModel(
        walletObjects: KNWalletStorage.shared.wallets,
        currentWallet: self.currentWallet
      )
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
    case .useLastMultisend:
      break
    }
  }
  
  fileprivate func requestBuildTx(items: [MultiSendItem], completion: @escaping (TxObject) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.session.wallet.address.description
    
    provider.request(.buildMultiSendTx(sender: address, items: items)) { result in
      if case .success(let resp) = result {
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(TransactionResponse.self, from: resp.data)
          completion(data.txObject)
          
        } catch let error {
          self.navigationController.showTopBannerView(message: error.localizedDescription)
        }
      } else {
        self.navigationController.showTopBannerView(message: "Build multiSend request is failed")
      }
    }
  }
  
  fileprivate func openSearchToken(selectedToken: TokenObject) {
    let tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
    let viewModel = KNSearchTokenViewModel(
      supportedTokens: tokens
    )
    let controller = KNSearchTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.searchTokensVC = controller
  }
  
  fileprivate func checkAllowance(contractAddress: String, items: [MultiSendItem], completion: @escaping ([MultiSendItem]) -> Void) {
    guard let provider = self.session.externalProvider else {
      self.navigationController.showErrorTopBannerMessage(message: "You are using watch wallet")
      return
    }
    
    var remaining: [MultiSendItem] = []
    let group = DispatchGroup()
    
    items.forEach { item in
      if let address = Address(string: item.2.address) {
        group.enter()
        
        provider.getAllowance(tokenAddress: address, toAddress: Address(string: contractAddress)) { result in
          switch result {
          case .success(let res):
            if item.1 > res {
              remaining.append(item)
            }
          case .failure:
            break
          }
          
          group.leave()
        }
      }
    }
    
    group.notify(queue: .main) {
      completion(remaining)
    }
  }
  
  fileprivate func openListContactsView() {
    let controller = KNListContactViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  fileprivate func openNewContact(address: String, ens: String?) {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: address, ens: ens)
    self.addContactVC.updateView(viewModel: viewModel)
    self.navigationController.pushViewController(self.addContactVC, animated: true)
  }
  
  fileprivate func openApproveView(items: [MultiSendItem]) {
    guard self.approveVC == nil else { return }
    let viewModel = MultiSendApproveViewModel(items: items)
    let controller = MultiSendApproveViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.approveVC = controller
  }

  fileprivate func openConfirmView(items: [MultiSendItem], txObject: TxObject) {
    guard self.confirmVC == nil else { return }
    let gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? BigInt.zero
    let vm = MultiSendConfirmViewModel(sendItems: items, gasPrice: KNGasCoordinator.shared.defaultKNGas, gasLimit: gasLimit, baseGasLimit: gasLimit)
    let controller = MultiSendConfirmViewController(viewModel: vm)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.confirmVC = controller
  }
  
  fileprivate func openGasPriceSelectView(_ gasLimit: BigInt, _ selectType: KNSelectedGasPriceType, _ baseGasLimit: BigInt, _ advancedGasLimit: String?, _ advancedPriorityFee: String?, _ advancedMaxFee: String?, _ advancedNonce: String?, _ controller: UIViewController) {
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
    
    self.getLatestNonce { result in
      switch result {
      case .success(let nonce):
        vc.coordinatorDidUpdateCurrentNonce(nonce)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(message: error.description)
      }
    }
    
    controller.present(vc, animated: true, completion: nil)
    self.gasPriceSelector = vc
  }
  
  fileprivate func openAddressListView(items: [MultiSendItem], controller: UIViewController) {
    let vm = MultisendAddressListViewModel(items: items)
    let vc = MultisendAddressListViewController(viewModel: vm)
    controller.present(vc, animated: true, completion: nil)
  }
  
  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
}

extension MultiSendCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true) {
      self.searchTokensVC = nil
      if case .select(let token) = event {
        self.rootViewController.coordinatorDidUpdateSendToken(token.toToken())
      } else if case .add(let token) = event {
        self.delegate?.sendTokenCoordinatorDidSelectAddToken(token)
      }
    }
  }
}

extension MultiSendCoordinator: KNListContactViewControllerDelegate {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .select(let contact) = event {
        self.rootViewController.coordinatorDidSelectContact(contact)
      } else if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}

extension MultiSendCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}

extension MultiSendCoordinator: MultiSendApproveViewControllerDelegate {

  func multiSendApproveVieController(_ controller: MultiSendApproveViewController, run event: MultiSendApproveViewEvent) {
    switch event {
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let selectType, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      openGasPriceSelectView(gasLimit, selectType, baseGasLimit, advancedGasLimit, advancedPriorityFee, advancedMaxFee, advancedNonce, controller)
    case .dismiss:
      self.approveVC = nil
    
    case .approve(items: let items, isApproveUnlimit: let isApproveUnlimit, settings: let setting):
      guard case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider else {
        return
      }
      
      let currentAddress = account.address.description
      controller.displayLoading()
      self.approvingItems = items
      self.getLatestNonce { nonceResult in
        switch nonceResult {
        case .success(let nonce):
          self.buildApproveDataList(items: items, isApproveUnlimit: isApproveUnlimit) { dataList in
            var eipTxs: [(MultiSendItem, EIP1559Transaction)] = []
            var legacyTxs: [(MultiSendItem, SignTransaction)] = []
            for (index, element) in dataList.enumerated() {
              let item = element.0
              let txNonce = nonce + index
              if KNGeneralProvider.shared.isUseEIP1559 {
                let tx = TransactionFactory.buildEIP1559Transaction(from: currentAddress, to: item.2.address, nonce: txNonce, data: element.1, setting: setting)
                eipTxs.append((item, tx))
              } else {
                let tx = TransactionFactory.buildLegacyTransaction(account: account, to: item.2.address, nonce: txNonce, data: element.1, setting: setting)
                legacyTxs.append((item, tx))
              }
            }
            print(eipTxs)
            print(legacyTxs)
            
            if !eipTxs.isEmpty {
              self.sendEIP1559Txs(eipTxs) { remaining in
                guard remaining.isEmpty else {
                  self.navigationController.showErrorTopBannerMessage(message: "Approval request is failed")
                  controller.hideLoading()
                  return
                }
                
              }
            } else if !legacyTxs.isEmpty {
              self.sendLegacyTxs(legacyTxs) { remaining in
                guard remaining.isEmpty else {
                  self.navigationController.showErrorTopBannerMessage(message: "Approval request is failed")
                  controller.hideLoading()
                  return
                }

              }
            }
          }
        case .failure( _):
          break
        }
      }
    case .done:
      self.approvingItems.removeAll()
      DispatchQueue.main.async {
        controller.hideLoading()
        controller.dismiss(animated: true) {
          self.rootViewController.coordinatorDidFinishApproveTokens()
          self.approveVC = nil
        }
      }
    }
  }

  fileprivate func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getTransactionCount { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  fileprivate func buildApproveDataList(items: [MultiSendItem], isApproveUnlimit: Bool, completion: @escaping ([(MultiSendItem, Data)]) -> Void) {
    guard let addressStr = self.processingTx?.to, let address = Address(string: addressStr) else { return }
    var dataList: [(MultiSendItem, Data)] = []
    let group = DispatchGroup()
    items.forEach { item in
      let value = isApproveUnlimit ? BigInt(2).power(256) - BigInt(1) : item.1
      group.enter()

      KNGeneralProvider.shared.getSendApproveERC20TokenEncodeData(networkAddress: address, value: value) { encodeResult in
        switch encodeResult {
        case .success(let data):
          dataList.append((item, data))
        case .failure( _):
          break
        }
        group.leave()
      }

      group.notify(queue: .global()) {
        completion(dataList)
      }
    }
  }

  fileprivate func sendEIP1559Txs(_ txs: [(MultiSendItem, EIP1559Transaction)], completion: @escaping ([MultiSendItem]) -> Void) {
    guard let provider = self.session.externalProvider else {
      self.navigationController.showErrorTopBannerMessage(message: "Watch wallet doesn't support this operation")
      return
    }
    var signedData: [(MultiSendItem, EIP1559Transaction, Data)] = []
    txs.forEach { element in
      if let data = provider.signContractGenericEIP1559Transaction(element.1) {
        signedData.append((element.0, element.1, data))
      }
    }
    
    let group = DispatchGroup()
    var unApproveItem: [MultiSendItem] = []
    signedData.forEach { txData in
      group.enter()
      let item = txData.0
      KNGeneralProvider.shared.sendRawTransactionWithInfura(txData.2, completion: { sendResult in
        switch sendResult {
        case .success(let hash):
          let historyTx = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: nil, toSymbol: nil, transactionDescription: "Approve \(item.2.name)", transactionDetailDescription: "", transactionObj: nil, eip1559Tx: txData.1)
          historyTx.hash = hash
          historyTx.time = Date()
          historyTx.nonce = Int(txData.1.nonce) ?? 0
          EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTx)
          
        case .failure( _):
          unApproveItem.append(txData.0)
        }

        group.leave()
      })
    }
    
    group.notify(queue: .main) {
      completion(unApproveItem)
    }
  }
  
  fileprivate func sendLegacyTxs(_ txs: [(MultiSendItem, SignTransaction)], completion: @escaping ([MultiSendItem]) -> Void) {
    guard let provider = self.session.externalProvider else {
      self.navigationController.showErrorTopBannerMessage(message: "Watch wallet doesn't support this operation")
      return
    }
    let group = DispatchGroup()
    var signedData: [(MultiSendItem, SignTransaction, Data)] = []
    txs.forEach { element in
      group.enter()
      provider.signTransactionData(from: element.1) { signResult in
        if case .success(let resultData) = signResult {
          signedData.append((element.0, element.1, resultData.0))
        }

        group.leave()
      }
      group.wait()
    }
    group.notify(queue: .global()) {
      let sendGroup = DispatchGroup()
      var unApproveItem: [MultiSendItem] = []
      signedData.forEach { txData in
        sendGroup.enter()
        let item = txData.0
        print("[Debug] \(txData.2.hexEncoded)")
        KNGeneralProvider.shared.sendRawTransactionWithInfura(txData.2, completion: { sendResult in
          switch sendResult {
          case .success(let hash):
            let historyTx = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: nil, toSymbol: nil, transactionDescription: "Approve \(item.2.name)", transactionDetailDescription: "", transactionObj: txData.1.toSignTransactionObject(), eip1559Tx:nil )
            historyTx.hash = hash
            historyTx.time = Date()
            historyTx.nonce = txData.1.nonce
            EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTx)
            
          case .failure( _):
            unApproveItem.append(txData.0)
          }
          
          sendGroup.leave()
        })
        sendGroup.wait()
      }

      sendGroup.notify(queue: .main) {
        completion(unApproveItem)
      }
    }
  }
  
}

extension MultiSendCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .infoPressed:
      break
    case .gasPriceChanged(let type, let value):
      self.approveVC?.coordinatorDidUpdateGasPriceType(type, value: value)
      self.confirmVC?.coordinatorDidUpdateGasPriceType(type, value: value)
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
    case .updateAdvancedSetting(let gasLimit, let maxPriorityFee, let maxFee):
      self.approveVC?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
      self.confirmVC?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
    case .updateAdvancedNonce(let nonce):
      self.approveVC?.coordinatorDidUpdateAdvancedNonce(nonce)
      self.confirmVC?.coordinatorDidUpdateAdvancedNonce(nonce)
    case .speedupTransaction(transaction: let transaction, original: let original):
      if let data = self.session.externalProvider?.signContractGenericEIP1559Transaction(transaction) {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
          switch sendResult {
          case .success(let hash):
            savedTx?.state = .speedup
            savedTx?.hash = hash
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            print(error.description)
            var errorMessage = "Speedup failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
          }
        })
      }
    case .cancelTransaction(transaction: let transaction, original: let original):
      if let data = self.session.externalProvider?.signContractGenericEIP1559Transaction(transaction) {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
        
        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
          switch sendResult {
          case .success(let hash):
            savedTx?.state = .cancel
            savedTx?.type = .transferETH
            savedTx?.transactionSuccessDescription = "-0 ETH"
            savedTx?.hash = hash
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            var errorMessage = "Cancel failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
          }
        })
      }
    case .speedupTransactionLegacy(legacyTransaction: let transaction, original: let original):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
       
        let speedupTx = transaction.toSignTransaction(account: account)
        speedupTx.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            savedTx?.state = .speedup
            savedTx?.hash = hash
            print("GasSelector][Legacy][Speedup][Sent] \(hash)")
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            var errorMessage = "Speedup failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
          }
        }
      }
    case .cancelTransactionLegacy(legacyTransaction: let transaction, original: let original):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(original.hash)
        
        let cancelTx = transaction.toSignTransaction(account: account)
        cancelTx.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            saved?.state = .cancel
            saved?.type = .transferETH
            saved?.transactionSuccessDescription = "-0 ETH"
            saved?.hash = hash
            print("GasSelector][Legacy][Cancel][Sent] \(hash)")
            if let unwrapped = saved {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
          case .failure(let error):
            var errorMessage = "Cancel failed"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = message
              }
            }
            self.navigationController.showTopBannerView(message: errorMessage)
          }
        }
      }
    default:
      break
    }
  }
}

extension MultiSendCoordinator: MultiSendConfirmViewControllerDelegate {
  func multiSendConfirmVieController(_ controller: MultiSendConfirmViewController, run event: MultiSendConfirmViewEvent) {
    switch event {
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let selectType, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      openGasPriceSelectView(gasLimit, selectType, baseGasLimit, advancedGasLimit, advancedPriorityFee, advancedMaxFee, advancedNonce, controller)
    case .dismiss:
      self.confirmVC = nil
      self.processingTx = nil
    case .confirm(setting: let setting):
      guard case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider else {
        return
      }
      guard let tx = self.processingTx else { return }
      self.rootViewController.coordinatorDidConfirmTx()
      self.navigationController.displayLoading()
      if KNGeneralProvider.shared.isUseEIP1559 {
        let tx = TransactionFactory.buildEIP1559Transaction(txObject: tx, setting: setting)
        guard let data = provider.signContractGenericEIP1559Transaction(tx) else {
          return
        }
        KNGeneralProvider.shared.sendRawTransactionWithInfura(data, completion: { sendResult in
          self.navigationController.hideLoading()
          switch sendResult {
          case .success(let hash):
            let historyTransaction = InternalHistoryTransaction(type: .transferToken, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: "MultiSend", transactionDetailDescription: "", transactionObj: nil, eip1559Tx: tx)
            historyTransaction.hash = hash
            historyTransaction.time = Date()
            historyTransaction.nonce = Int(tx.nonce.drop0x, radix: 16) ?? 0
            EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
            self.openTransactionStatusPopUp(transaction: historyTransaction)
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.localizedDescription)
          }
        })
      } else {
        let tx = TransactionFactory.buildLegaryTransaction(txObject: tx, account: account, setting: setting)
        KNGeneralProvider.shared.getEstimateGasLimit(transaction: tx) { result in
          self.navigationController.hideLoading()
          switch result {
          case .success(_):
            provider.signTransactionData(from: tx) { result in
              switch result {
              case .success(let signedData):
                print(signedData.0.hexEncoded)
                KNGeneralProvider.shared.sendRawTransactionWithInfura(signedData.0) { sendResult in
                  switch sendResult {
                  case .success(let hash):
                    let historyTransaction = InternalHistoryTransaction(type: .transferToken, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: "MultiSend", transactionDetailDescription: "", transactionObj: tx.toSignTransactionObject(), eip1559Tx: nil)
                    historyTransaction.hash = hash
                    historyTransaction.time = Date()
                    historyTransaction.nonce = tx.nonce
                    EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                    self.openTransactionStatusPopUp(transaction: historyTransaction)
                  case .failure(let error):
                    self.navigationController.showTopBannerView(message: error.localizedDescription)
                  }
                }
              case .failure(let error):
                var errorMessage = "Can not sign transaction data"
                if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
                  if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                    errorMessage = message
                  }
                }
                self.navigationController.showErrorTopBannerMessage(message: errorMessage)
              }

            }
          case .failure(let error):
            var errorMessage = "Can not estimate Gas Limit"
            if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
              if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
                errorMessage = "Cannot estimate gas, please try again later. Error: \(message)"
              }
            }
            self.navigationController.showErrorTopBannerMessage(message: errorMessage)
            self.navigationController.hideLoading()
          }
        }
      }

      self.confirmVC = nil
      self.processingTx = nil
    case .showAddresses(let items):
      self.openAddressListView(items: items, controller: controller)
    }
  }
}

extension MultiSendCoordinator: KNTransactionStatusPopUpDelegate {
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
      self.navigationController.openSafari(with: "https://support.krystal.app")
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

    viewModel.isSpeedupMode = true
    viewModel.transaction = transaction
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.gasPriceSelector = vc
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
    self.gasPriceSelector = vc
    self.navigationController.present(vc, animated: true, completion: nil)
  }
}

extension MultiSendCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.sendTokenCoordinatorDidSelectManageWallet()
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
      self.delegate?.sendTokenViewCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.sendTokenCoordinatorDidSelectAddWallet()
    }
  }
}

extension MultiSendCoordinator: QRCodeReaderDelegate {
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
