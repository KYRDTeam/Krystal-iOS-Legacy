//
//  MultiSendCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import Foundation
import BigInt
import Result
import Moya
import APIKit
import JSONRPCKit
import QRCodeReaderViewController
import MBProgressHUD
import WalletConnectSwift
import KrystalWallets
import Dependencies
import TokenModule

class MultiSendCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  
  weak var delegate: KNSendTokenViewCoordinatorDelegate?
  
  lazy var rootViewController: MultiSendViewController = {
    let vm = MultiSendViewModel()
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
  
  fileprivate(set) var approveVC: MultiSendApproveViewController?
  fileprivate(set) weak var gasPriceSelector: GasFeeSelectorPopupViewController?
  fileprivate(set) var confirmVC: MultiSendConfirmViewController?
  fileprivate(set) var processingTx: TxObject?
  fileprivate(set) var transactionStatusVC: KNTransactionStatusPopUp?
  
  var approvingItems: [ApproveMultiSendItem] = []
  var allowance: [Token: BigInt] = [:]
  var approveRequestCountDown = 0
  var isRequestingApprove = false
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
  }
  
  func start() {
    guard self.navigationController.viewControllers.last != self.rootViewController else { return }
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
  }
  
  func stop() {
    self.navigationController.popToRootViewController(animated: true, completion: nil)
  }
  
  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if tx.state == .done, tx.type == .allowance {
      let approveName = String(tx.transactionDescription.dropFirst(8))
      if let found = self.approvingItems.first(where: { element in
        return approveName == element.1.name
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

  func appCoordinatorSwitchAddress() {
    self.rootViewController.coordinatorAppSwitchAddress()
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
      if currentAddress.isWatchWallet {
        self.navigationController.showErrorTopBannerMessage(message: "You are using watch wallet")
        return
      }
      self.navigationController.displayLoading()
      self.requestBuildTx(items: items) { object in
        self.processingTx = object
        let allTokens = items.map({ item in
          return item.2
        })
        let allTokenSet = Set(allTokens)
        var approveItems: [ApproveMultiSendItem] = []
        allTokenSet.forEach { element in
          var amount = BigInt.zero
          let sendItems = items.filter { itemElement in
            return element == itemElement.2
          }
          sendItems.forEach { foundItem in
            amount += foundItem.1
          }
          approveItems.append((amount, element))
        }
        
        self.checkAllowance(contractAddress: object.to, items: approveItems) { remaining in
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
        self.navigationController.hideLoading()
        switch result {
        case .success(let nonce):
          let nonceStr = BigInt(nonce).hexEncoded.hexSigned2Complement
          self.processingTx?.nonce = nonceStr
          if let tx = self.processingTx, let gasLimit = BigInt(tx.gasLimit.drop0x, radix: 16), !gasLimit.isZero {
            self.navigationController.hideLoading()
            self.openConfirmView(items: items, txObject: tx)
          } else {
            self.openConfirmViewAfterRequestBuildTx(items: items, nonce: nonceStr)
          }
        case .failure(let error):
          self.navigationController.hideLoading()
          self.showErrorMessage(error, viewController: self.navigationController)
        }
        
      }
    case .openHistory:
      AppDependencies.router.openTransactionHistory()
    case .useLastMultisend:
      break
    }
  }
  
  fileprivate func openConfirmViewAfterRequestBuildTx(items: [MultiSendItem], nonce: String) {
    self.requestBuildTx(items: items) { object in
      guard let gasLimit = BigInt(object.gasLimit.drop0x, radix: 16), !gasLimit.isZero else {
          self.navigationController.showTopBannerView(message: Strings.estGasErrorMessage)
        return
      }
      self.processingTx = object
      self.processingTx?.nonce = nonce
      DispatchQueue.main.async {
        self.navigationController.hideLoading()
        self.openConfirmView(items: items, txObject: object)
      }
    }
  }
  
  fileprivate func requestBuildTx(items: [MultiSendItem], completion: @escaping (TxObject) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
    let address = currentAddress.addressString
    
    provider.requestWithFilter(.buildMultiSendTx(sender: address, items: items)) { result in
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
      TokenModule.openSearchToken(on: self.rootViewController) { selected in
          self.rootViewController.coordinatorDidUpdateSendToken(selected.token)
      }
  }
  
  fileprivate func checkAllowance(contractAddress: String, items: [ApproveMultiSendItem], completion: @escaping ([ApproveMultiSendItem]) -> Void) {
    guard !currentAddress.isWatchWallet else {
      self.navigationController.showErrorTopBannerMessage(message: "You are using watch wallet")
      return
    }
    
    var remaining: [ApproveMultiSendItem] = []
    let group = DispatchGroup()
    let web3Sevice = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
    
    items.forEach { item in
      group.enter()
      web3Sevice.getAllowance(for: currentAddress.addressString, networkAddress: contractAddress, tokenAddress: item.1.address) { result in
        switch result {
        case .success(let response):
          if item.0 > response {
            remaining.append(item)
            self.allowance[item.1] = response
          }
        default:
          break
        }
        group.leave()
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
  
  fileprivate func openApproveView(items: [ApproveMultiSendItem]) {
    guard self.approveVC == nil else { return }
    let viewModel = MultiSendApproveViewModel(items: items, allowances: self.allowance)
    let controller = MultiSendApproveViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.approveVC = controller
    Tracker.track(event: .multisendApprove, customAttributes: ["numberAddress": items.count])
  }
  
  fileprivate func openConfirmView(items: [MultiSendItem], txObject: TxObject) {
    guard self.confirmVC == nil else { return }
    let gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? BigInt.zero
    let vm = MultiSendConfirmViewModel(sendItems: items, gasPrice: KNGasCoordinator.shared.defaultKNGas, gasLimit: gasLimit, baseGasLimit: gasLimit)
    let controller = MultiSendConfirmViewController(viewModel: vm)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.confirmVC = controller
    let allAddresses = items.map { element in
      return element.0
    }
    
    Tracker.track(event: .multisendConfirm, customAttributes: ["numberAddress": Set(allAddresses)])
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
      
      if case .dismiss = event {
        self.rootViewController.coordinatorDidAddNewContact()
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
      
    case .approve(items: let items, isApproveUnlimit: let isApproveUnlimit, settings: let setting, estNoTx: let noTx):
      if currentAddress.isWatchWallet {
        return
      }
      controller.displayLoading()
      self.approvingItems = items
      self.getLatestNonce { nonceResult in
        switch nonceResult {
        case .success(let nonce):
          self.approveRequestCountDown = noTx
          self.isRequestingApprove = false
          self.buildApproveDataList(items: items, isApproveUnlimit: isApproveUnlimit) { dataList in
            guard dataList.count == noTx else { return }
            var eipTxs: [(ApproveMultiSendItem, EIP1559Transaction)] = []
            var legacyTxs: [(ApproveMultiSendItem, SignTransaction)] = []
            for (index, element) in dataList.enumerated() {
              let item = element.0
              let txNonce = nonce + index
              if KNGeneralProvider.shared.isUseEIP1559 {
                let tx = TransactionFactory.buildEIP1559Transaction(from: self.currentAddress.addressString, to: item.1.address, nonce: txNonce, data: element.1, setting: setting)
                eipTxs.append((item, tx))
              } else {
                let tx = TransactionFactory.buildLegacyTransaction(address: self.currentAddress.addressString, to: item.1.address, nonce: txNonce, data: element.1, setting: setting)
                legacyTxs.append((item, tx))
              }
            }
            
            if !eipTxs.isEmpty {
              self.sendEIP1559Txs(eipTxs) { remaining in
                guard remaining.0.isEmpty else {
                  if let error = remaining.1.first {
                    self.showErrorMessage(error, viewController: self.navigationController)
                  } else {
                    self.navigationController.showErrorTopBannerMessage(message: "Approval request is failed")
                  }
                  
                  controller.hideLoading()
                  return
                }
              }
            } else if !legacyTxs.isEmpty {
              self.sendLegacyTxs(legacyTxs) { remaining in
                guard remaining.0.isEmpty else {
                  if let error = remaining.1.first {
                    self.showErrorMessage(error, viewController: self.navigationController)
                  } else {
                    self.navigationController.showErrorTopBannerMessage(message: "Approval request is failed")
                  }
                  
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
      self.allowance.removeAll()
      DispatchQueue.main.async {
        controller.hideLoading()
        controller.dismiss(animated: true) {
          self.rootViewController.coordinatorDidFinishApproveTokens()
          self.approveVC = nil
        }
      }
    case .estimateGas(items: let items):
      if currentAddress.isWatchWallet {
        return
      }
      
      self.buildApproveDataList(items: items, isApproveUnlimit: true) { dataList in
        var eipTxs: [(ApproveMultiSendItem, EIP1559Transaction)] = []
        var legacyTxs: [(ApproveMultiSendItem, SignTransaction)] = []
        let currentAddress = self.currentAddress.addressString
        
        let setting = ConfirmAdvancedSetting(
          gasPrice: KNGasCoordinator.shared.defaultKNGas.description,
          gasLimit: KNGasConfiguration.approveTokenGasLimitDefault.description,
          advancedGasLimit: nil,
          advancedPriorityFee: nil,
          avancedMaxFee: nil,
          advancedNonce: nil
        )
        for (_, element) in dataList.enumerated() {
          let item = element.0
          let txNonce = 1
          if KNGeneralProvider.shared.isUseEIP1559 {
            let tx = TransactionFactory.buildEIP1559Transaction(from: currentAddress, to: item.1.address, nonce: txNonce, data: element.1, setting: setting)
            eipTxs.append((item, tx))
          } else {
            let tx = TransactionFactory.buildLegacyTransaction(address: currentAddress, to: item.1.address, nonce: txNonce, data: element.1, setting: setting)
            legacyTxs.append((item, tx))
          }
        }
        
        var output: [(ApproveMultiSendItem, BigInt)] = []
        var gasRequests: [(ApproveMultiSendItem, GasLimitRequestable)]  = KNGeneralProvider.shared.isUseEIP1559 ? eipTxs : legacyTxs
        
        let group = DispatchGroup()
        gasRequests.forEach { item in
          group.enter()
          KNGeneralProvider.shared.getEstimateGasLimit(request: item.1.createGasLimitRequest()) { result in
            switch result {
            case.success(let gas):
              if let previousGas = output.last?.1 {
                output.append((item.0, gas + previousGas))
              } else {
                output.append((item.0, gas))
              }
              
            default:
              output.append((item.0, KNGasConfiguration.approveTokenGasLimitDefault))
            }
            group.leave()
          }
        }
        group.notify(queue: .global()) {
          controller.coordinatorDidUpdateGasLimit(gas: output)
        }
      }
    }
  }
  
  fileprivate func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
    if currentAddress.isWatchWallet {
      return
    }
    EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain).getTransactionCount(for: currentAddress.addressString) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  fileprivate func buildApproveDataList(items: [ApproveMultiSendItem], isApproveUnlimit: Bool, completion: @escaping ([(ApproveMultiSendItem, Data)]) -> Void) {
    guard let addressStr = self.processingTx?.to else { return }
    var dataList: [(ApproveMultiSendItem, Data)] = []
    
    let group = DispatchGroup()
    items.forEach { item in
      if let remainAllowance = self.allowance[item.1], !remainAllowance.isZero {
        let resetItem = (BigInt.zero, item.1)
        
        group.enter()
        KNGeneralProvider.shared.getSendApproveERC20TokenEncodeData(networkAddress: addressStr, value: BigInt.zero) { encodeResult in
          switch encodeResult {
          case .success(let data):
            dataList.append((resetItem, data))
          case .failure( _):
            break
          }
          group.leave()
        }
      }
      
      let value = isApproveUnlimit ? Constants.maxValueBigInt : item.0
      group.enter()
      
      KNGeneralProvider.shared.getSendApproveERC20TokenEncodeData(networkAddress: addressStr, value: value) { encodeResult in
        switch encodeResult {
        case .success(let data):
          dataList.append((item, data))
        case .failure( _):
          break
        }
        group.leave()
      }
      
      group.notify(queue: .main) {
        completion(dataList)
      }
    }
  }
  
  fileprivate func sendEIP1559Txs(_ txs: [(ApproveMultiSendItem, EIP1559Transaction)], completion: @escaping (([ApproveMultiSendItem], [AnyError])) -> Void) {
    if currentAddress.isWatchWallet {
      self.navigationController.showErrorTopBannerMessage(message: Strings.watchWalletNotSupportOperation)
      return
    }
    guard approveRequestCountDown == txs.count, !self.isRequestingApprove else { return }
    self.isRequestingApprove = true
    var signedData: [(ApproveMultiSendItem, EIP1559Transaction, Data)] = []
    let signer = EIP1559TransactionSigner()
    txs.forEach { element in
      if let data = signer.signTransaction(address: currentAddress, eip1559Tx: element.1) {
        signedData.append((element.0, element.1, data))
      }
    }
    
    let group = DispatchGroup()
    var unApproveItem: [ApproveMultiSendItem] = []
    var errors: [AnyError] = []
    signedData.forEach { txData in
      group.enter()
      let item = txData.0
      KNGeneralProvider.shared.sendRawTransactionWithInfura(txData.2, completion: { sendResult in
        switch sendResult {
        case .success(let hash):
          let message = item.0.isZero ? "Reset \(item.1.name) approval" : "Approve \(item.1.name)"
          let historyTx = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: nil, toSymbol: nil, transactionDescription: message, transactionDetailDescription: "", transactionObj: nil, eip1559Tx: txData.1)
          historyTx.hash = hash
          historyTx.time = Date()
          historyTx.nonce = Int(txData.1.nonce) ?? 0
            
            
          EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTx)
        case .failure(let error):
          unApproveItem.append(txData.0)
          errors.append(error)
        }
        self.approveRequestCountDown -= 1
        group.leave()
      })
    }
    group.notify(queue: .main) {
      guard self.approveRequestCountDown == 0 else { return }
      self.isRequestingApprove = false
      completion((unApproveItem, errors))
    }
  }
  
  fileprivate func sendLegacyTxs(_ txs: [(ApproveMultiSendItem, SignTransaction)], completion: @escaping (([ApproveMultiSendItem], [AnyError])) -> Void) {
    if currentAddress.isWatchWallet {
      self.navigationController.showErrorTopBannerMessage(message: Strings.watchWalletNotSupportOperation)
      return
    }
    let signer = EthereumTransactionSigner()
    let signedData: [(ApproveMultiSendItem, SignTransaction, Data)] = txs.compactMap { (item, signTx) in
      let signResult = signer.signTransaction(address: currentAddress, transaction: signTx)
      switch signResult {
      case .success(let data):
        return (item, signTx, data)
      case .failure:
        return nil
      }
    }
    
    guard self.approveRequestCountDown == txs.count, !self.isRequestingApprove else { return }
    self.isRequestingApprove = true
    let sendGroup = DispatchGroup()
    var unApproveItem: [ApproveMultiSendItem] = []
    var errors: [AnyError] = []
    signedData.forEach { txData in
      sendGroup.enter()
      let item = txData.0
      
      KNGeneralProvider.shared.sendRawTransactionWithInfura(txData.2, completion: { sendResult in
        switch sendResult {
        case .success(let hash):
          let message = item.0.isZero ? "Reset \(item.1.name) approval" : "Approve \(item.1.name)"
          let historyTx = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: nil, toSymbol: nil, transactionDescription: message, transactionDetailDescription: "", transactionObj: txData.1.toSignTransactionObject(), eip1559Tx: nil )
          historyTx.hash = hash
          historyTx.time = Date()
          historyTx.nonce = txData.1.nonce
          EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTx)
          
        case .failure(let error):
          unApproveItem.append(txData.0)
          errors.append(error)
        }
        self.approveRequestCountDown -= 1
        sendGroup.leave()
      })
    }
    
    sendGroup.notify(queue: .main) {
      guard self.approveRequestCountDown == 0 else { return }
      self.isRequestingApprove = false
      completion((unApproveItem, errors))
    }
  }
  
}

extension MultiSendCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
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

extension MultiSendCoordinator: MultiSendConfirmViewControllerDelegate {
  func multiSendConfirmVieController(_ controller: MultiSendConfirmViewController, run event: MultiSendConfirmViewEvent) {
    switch event {
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let selectType, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      openGasPriceSelectView(gasLimit, selectType, baseGasLimit, advancedGasLimit, advancedPriorityFee, advancedMaxFee, advancedNonce, controller)
    case .dismiss:
      self.confirmVC = nil
      self.processingTx = nil
    case .confirm(setting: let setting):
      if currentAddress.isWatchWallet {
        return
      }
      guard let tx = self.processingTx else { return }
      let valueBigInt = BigInt(tx.value.drop0x, radix: 16) ?? BigInt.zero
      let valueString = valueBigInt.string(
        decimals: 18,
        minFractionDigits: 0,
        maxFractionDigits: 5
      )
      let valueText = "- \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      let toAddress = tx.to
      self.rootViewController.coordinatorDidConfirmTx()
      self.navigationController.displayLoading()
      if KNGeneralProvider.shared.isUseEIP1559 {
        let tx = TransactionFactory.buildEIP1559Transaction(txObject: tx, setting: setting)
        guard let data = EIP1559TransactionSigner().signTransaction(address: currentAddress, eip1559Tx: tx) else {
          return
        }
        KNGeneralProvider.shared.sendRawTransactionWithInfura(data, completion: { sendResult in
          self.navigationController.hideLoading()
          switch sendResult {
          case .success(let hash):
            
            let historyTransaction = InternalHistoryTransaction(type: .multiSend, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: valueText, transactionDetailDescription: toAddress, transactionObj: nil, eip1559Tx: tx)
            historyTransaction.hash = hash
            historyTransaction.time = Date()
            historyTransaction.nonce = Int(tx.nonce.drop0x, radix: 16) ?? 0
              
            let data = self.rootViewController.viewModel.buildExtraData()
            historyTransaction.trackingExtraData = MultisendExtraData(data: data, amountUsd: "0")
              
            EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
            self.openTransactionStatusPopUp(transaction: historyTransaction)
          case .failure(let error):
            self.showErrorMessage(error, viewController: self.navigationController)
          }
        })
      } else {
        let tx = TransactionFactory.buildLegacyTransaction(txObject: tx, address: currentAddress.addressString, setting: setting)
        KNGeneralProvider.shared.getEstimateGasLimit(transaction: tx) { result in
          self.navigationController.hideLoading()
          switch result {
          case .success(_):
            let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: tx)
            switch signResult {
            case .success(let data):
              KNGeneralProvider.shared.sendRawTransactionWithInfura(data) { sendResult in
                switch sendResult {
                case .success(let hash):
                  let historyTransaction = InternalHistoryTransaction(type: .multiSend, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: valueText, transactionDetailDescription: toAddress, transactionObj: tx.toSignTransactionObject(), eip1559Tx: nil)
                  historyTransaction.hash = hash
                  historyTransaction.time = Date()
                  historyTransaction.nonce = tx.nonce
                  let data = self.rootViewController.viewModel.buildExtraData()
                  historyTransaction.trackingExtraData = MultisendExtraData(data: data, amountUsd: "0")
                  EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
                  self.openTransactionStatusPopUp(transaction: historyTransaction)
                case .failure(let error):
                  self.showErrorMessage(error, viewController: self.navigationController)
                }
              }
            case .failure(let error):
              self.showErrorMessage(error, viewController: self.navigationController)
            }
          case .failure(let error):
            self.showErrorMessage(error, viewController: self.navigationController)
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
    case .openLink(let url):
      self.navigationController.openSafari(with: url)
    case .speedUp(let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .goToSupport:
      self.navigationController.openSafari(with: "https://support.krystal.app")
    case .dismiss:
      self.stop()
    case .transfer:
      self.rootViewController.coordinatorResetForNewTransfer()
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
