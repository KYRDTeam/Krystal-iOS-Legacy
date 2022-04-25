// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import Result
import Moya
import APIKit
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnectSwift
import JSONRPCKit
import WalletCore

protocol KNSendTokenViewCoordinatorDelegate: class {
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet)
  func sendTokenViewCoordinatorSelectOpenHistoryList()
  func sendTokenCoordinatorDidSelectManageWallet()
  func sendTokenCoordinatorDidSelectAddWallet()
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject)
  func sendTokenCoordinatorDidClose()
}

class KNSendTokenViewCoordinator: NSObject, Coordinator {
  weak var delegate: KNSendTokenViewCoordinatorDelegate?

  let navigationController: UINavigationController
  fileprivate var session: KNSession
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]
  fileprivate var from: TokenObject
  fileprivate var nftItem: NFTItem = NFTItem()
  fileprivate var nftCategory: NFTSection = NFTSection(collectibleName: "", collectibleAddress: "", collectibleSymbol: "", collectibleLogo: "", items: [])
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.addressString
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  var rootViewController: KSendTokenViewController?
  
  var sendNFTController: SendNFTViewController?

  fileprivate(set) var searchTokensVC: KNSearchTokenViewController?
  fileprivate(set) var confirmVC: KConfirmSendViewController?
  fileprivate(set) weak var gasPriceSelector: GasFeeSelectorPopupViewController?
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  
  fileprivate var isSupportERC721 = true

  lazy var addContactVC: KNNewContactViewController = {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: "")
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var multiSendCoordinator: MultiSendCoordinator = {
    let coordinator = MultiSendCoordinator(navigationController: self.navigationController, session: self.session)
    coordinator.delegate = self.delegate
    return coordinator
  }()
  //Get solana private key
  lazy var privateKey: PrivateKey? = {
    guard let account = self.session.keystore.matchWithEvmAccount(address: self.currentWallet.evmAddress) else {
      return nil
    }
    let result = self.session.keystore.exportMnemonics(account: account)
    if case .success(let seeds) = result {
      let privateKey = SolanaUtil.seedsToPrivateKey(seeds)
      return privateKey
    }

    return nil
  }()
  
  //Get privatekey with PK import
  lazy var privateKeyForPKWallet: PrivateKey? = {
    return self.session.keystore.solanaUtil.exportKeyPair(walletID: self.currentWallet.walletID)
  }()

  deinit {
    self.rootViewController?.removeObserveNotification()
  }

  init(
    navigationController: UINavigationController,
    session: KNSession,
    balances: [String: Balance],
    from: TokenObject = KNGeneralProvider.shared.quoteTokenObject
    ) {
    self.navigationController = navigationController
    self.session = session
    self.balances = balances
    self.from = from
  }
  
  init(
    navigationController: UINavigationController,
    session: KNSession,
    nftItem: NFTItem,
    supportERC721: Bool,
    nftCategory: NFTSection
  ) {
    self.navigationController = navigationController
    self.session = session
    self.nftItem = nftItem
    self.nftCategory = nftCategory
    self.from = KNGeneralProvider.shared.quoteTokenObject
    self.isSupportERC721 = supportERC721
  }

  func start(sendNFT: Bool = false) {
    if sendNFT {
      let controller = SendNFTViewController(viewModel: SendNFTViewModel(item: self.nftItem, category: self.nftCategory, supportERC721: self.isSupportERC721))
      controller.delegate = self
      self.sendNFTController = controller
      self.navigationController.pushViewController(controller, animated: true)
    } else {
      let address = self.session.wallet.addressString
      let viewModel = KNSendTokenViewModel(
        from: self.from,
        balances: self.balances,
        currentAddress: address
      )
      let controller = KSendTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true)
      self.rootViewController = controller
      self.rootViewController?.coordinatorUpdateBalances(self.balances)
    }
    
    print("[Debug] \(self.privateKeyForPKWallet)")
  }

  func stop() {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.sendTokenCoordinatorDidClose()
    }
  }
}

// MARK: Update from coordinator
extension KNSendTokenViewCoordinator {
  func coordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.rootViewController?.coordinatorUpdateBalances(self.balances)
    self.searchTokensVC?.updateBalances(self.balances)
  }

  func coordinatorShouldOpenSend(from token: TokenObject) {
    self.rootViewController?.coordinatorDidUpdateSendToken(token, balance: self.balances[token.contract])
  }

  func coordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.searchTokensVC?.updateListSupportedTokens(tokenObjects)
  }

  func coordinatorGasPriceCachedDidUpdate() {
    self.rootViewController?.coordinatorUpdateGasPriceCached()
    self.sendNFTController?.coordinatorUpdateGasPriceCached()
    self.gasPriceSelector?.coordinatorDidUpdateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
  }

  func coordinatorOpenSendView(to address: String) {
    self.rootViewController?.coordinatorSend(to: address)
  }

  func coordinatorDidUpdateTrackerRate() {
    self.rootViewController?.coordinatorUpdateTrackerRate()
  }

  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if self.multiSendCoordinator.coordinatorDidUpdateTransaction(tx) == true { return true }
    if let txHash = self.transactionStatusVC?.transaction.hash, txHash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.rootViewController?.coordinatorDidUpdatePendingTx()
    self.multiSendCoordinator.coordinatorDidUpdatePendingTx()
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.rootViewController?.coordinatorUpdateNewSession(wallet: session.wallet)
    self.multiSendCoordinator.appCoordinatorDidUpdateNewSession(session)
  }

  func appCoordinatorDidUpdateChain() {
    self.rootViewController?.coordinatorDidUpdateChain()
    self.multiSendCoordinator.appCoordinatorDidUpdateChain()
  }
}

// MARK: Send Token View Controller Delegate
extension KNSendTokenViewCoordinator: KSendTokenViewControllerDelegate {
  func kSendTokenViewController(_ controller: KNBaseViewController, run event: KSendTokenViewEvent) {
    switch event {
    case .back:
      self.stop()
    case .setGasPrice:
      break
    case .estimateGas(let transaction):
      self.estimateGasLimit(for: transaction)
    case .searchToken(let selectedToken):
      self.openSearchToken(selectedToken: selectedToken)
    case .validate:
      // validate transaction before transfer,
      // currently only validate sender's address, could be added more later
      guard self.session.externalProvider != nil else {
        self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
        return
      }

      controller.displayLoading()
      self.sendGetPreScreeningWalletRequest { [weak self] (result) in
        controller.hideLoading()
        guard let `self` = self else { return }
        var message: String?
        if case .success(let resp) = result,
          let json = try? resp.mapJSON() as? JSONDictionary ?? [:] {
          if let status = json["eligible"] as? Bool {
            if isDebug { print("eligible status : \(status)") }
            if status == false { message = json["message"] as? String }
          }
        }
        if let errorMessage = message {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: errorMessage,
            time: 2.0
          )
        } else {
          self.rootViewController?.coordinatorDidValidateTransferTransaction()
        }
      }
    case .validateSolana:
      controller.displayLoading()
      self.sendGetPreScreeningWalletRequest { [weak self] (result) in
        controller.hideLoading()
        guard let `self` = self else { return }
        var message: String?
        if case .success(let resp) = result,
          let json = try? resp.mapJSON() as? JSONDictionary ?? [:] {
          if let status = json["eligible"] as? Bool {
            if isDebug { print("eligible status : \(status)") }
            if status == false { message = json["message"] as? String }
          }
        }
        if let errorMessage = message {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: errorMessage,
            time: 2.0
          )
        } else {
          self.rootViewController?.coordinatorDidValidateSolTransferTransaction()
        }
      }

    case .send(let transaction, let ens):
      self.openConfirmTransfer(transaction: transaction, ens: ens)
    case .sendSolana(transaction: let transaction):
      self.openConfirmSolTransfer(transaction: transaction)
    case .addContact(let address, let ens):
      self.openNewContact(address: address, ens: ens)
    case .contactSelectMore:
      self.openListContactsView()
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let selectType, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
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

      self.navigationController.present(vc, animated: true, completion: nil)
      self.gasPriceSelector = vc
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
    case .sendNFT(item: let item, category: let category, gasPrice: let gasPrice, gasLimit: let gasLimit, to: let to, amount: let amount, ens: let ens, isERC721: let isSupportERC721, advancedGasLimit: let advancedGasLimit, advancedPriorityFee: let advancedPriorityFee, advancedMaxFee: let advancedMaxFee, advancedNonce: let advancedNonce):
      let vm = ConfirmSendNFTViewModel(nftItem: item, nftCategory: category, gasPrice: gasPrice, gasLimit: gasLimit, address: to, ens: ens, amount: amount, supportERC721: isSupportERC721, advancedGasLimit: advancedGasLimit, advancedMaxPriorityFee: advancedPriorityFee, advancedMaxFee: advancedMaxFee, advancedNonce: advancedNonce)
      let vc = ConfirmSendNFTViewController(viewModel: vm)
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    case .estimateGasLimitTransferNFT(to: let to, item: let item, category: let category, gasPrice: let gasPrice, gasLimit: let gasLimit, amount: let amount, isERC721: let isERC721):
      guard let provider = self.session.externalProvider else {
        return
      }
      provider.getEstimateGasLimitForTransferNFT(to: to, categoryAddress: category.collectibleAddress, tokenID: item.tokenID, gasPrice: gasPrice, gasLimit: gasLimit, amount: amount, isERC721: isERC721) { result in
        if case .success(let gasLimit) = result {
          self.sendNFTController?.coordinatorUpdateEstimatedGasLimit(
            gasLimit
          )
          self.gasPriceSelector?.coordinatorDidUpdateGasLimit(gasLimit)
        } else {
          self.rootViewController?.coordinatorFailedToUpdateEstimateGasLimit()
        }
      }
    case .openMultiSend:
      self.multiSendCoordinator.start()
      KNCrashlyticsUtil.logCustomEvent(withName: "transfer_click_multiple_transfer", customAttributes: nil)
    }
  }

  fileprivate func sendGetPreScreeningWalletRequest(completion: @escaping (Result<Moya.Response, MoyaError>) -> Void) {
    let address = self.session.wallet.addressString
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<UserInfoService>()
      provider.request(.getPreScreeningWallet(address: address)) { result in
        DispatchQueue.main.async {
          completion(result)
        }
      }
    }
  }

  fileprivate func estimateGasLimit(for transaction: UnconfirmedTransaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getEstimateGasLimit(
    for: transaction) { [weak self] result in
      if case .success(let gasLimit) = result {
        self?.rootViewController?.coordinatorUpdateEstimatedGasLimit(
          gasLimit,
          from: transaction.transferType.tokenObject(),
          address: transaction.to?.description ?? ""
        )
        self?.gasPriceSelector?.coordinatorDidUpdateGasLimit(gasLimit)
      } else {
        self?.rootViewController?.coordinatorFailedToUpdateEstimateGasLimit()
      }
    }
  }

  fileprivate func openSearchToken(selectedToken: TokenObject) {
    let tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
    self.searchTokensVC = {
      let viewModel = KNSearchTokenViewModel(
        supportedTokens: tokens
      )
      let controller = KNSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.present(self.searchTokensVC!, animated: true, completion: nil)
    self.searchTokensVC?.updateBalances(self.balances)
  }

  fileprivate func openConfirmTransfer(transaction: UnconfirmedTransaction, ens: String?) {
    self.confirmVC = {
      let viewModel = KConfirmSendViewModel(transaction: transaction, ens: ens)
      let controller = KConfirmSendViewController(viewModel: viewModel)
      controller.delegate = self
      controller.loadViewIfNeeded()
      return controller
    }()
    self.navigationController.present(self.confirmVC!, animated: true, completion: nil)
  }
  
  fileprivate func openConfirmSolTransfer(transaction: UnconfirmedSolTransaction) {
    self.confirmVC = {
      let viewModel = KConfirmSendViewModel(solTransaction: transaction)
      let controller = KConfirmSendViewController(viewModel: viewModel)
      controller.delegate = self
      controller.loadViewIfNeeded()
      return controller
    }()
    self.navigationController.present(self.confirmVC!, animated: true, completion: nil)
  }

  fileprivate func openNewContact(address: String, ens: String?) {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: address, ens: ens)
    self.addContactVC.updateView(viewModel: viewModel)
    self.navigationController.pushViewController(self.addContactVC, animated: true)
  }

  fileprivate func openListContactsView() {
    let controller = KNListContactViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
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
}

// MARK: Search Token Delegate
extension KNSendTokenViewCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true) {
      self.searchTokensVC = nil
      if case .select(let token) = event {
        let balance = self.balances[token.contract]
        self.rootViewController?.coordinatorDidUpdateSendToken(token, balance: balance)
      } else if case .add(let token) = event {
        self.delegate?.sendTokenCoordinatorDidSelectAddToken(token)
      }
    }
  }
}

// MARK: Confirm Transaction Delegate
extension KNSendTokenViewCoordinator: KConfirmSendViewControllerDelegate {
  func kConfirmSendViewController(_ controller: KNBaseViewController, run event: KConfirmViewEvent) {
    switch event {
    case .confirm(let type, let historyTransaction):
      if case .transfer(let transaction) = type {
        guard self.session.externalProvider != nil else {
          return
        }
        self.didConfirmTransfer(transaction, historyTransaction: historyTransaction)
        controller.dismiss(animated: true, completion: nil)
        self.confirmVC = nil
        self.navigationController.displayLoading()
      }
    case .confirmSolana(let transaction, let historyTransaction):
      controller.dismiss(animated: true) {
        self.didConfirmSolTransfer(transaction, historyTransaction)
      }
    case .cancel:
      controller.dismiss(animated: true) {
        self.confirmVC = nil
      }
    case .confirmNFT(nftItem: let nftItem, nftCategory: let nftCategory, gasPrice: let gasPrice, gasLimit: let gasLimit, address: let address, amount: let amount, isSupportERC721: let isSupportERC721, historyTransaction: let historyTransaction, advancedGasLimit: let advancedGasLimit, advancedPriorityFee: let advancedPriorityFee, advancedMaxFee: let advancedMaxFee, advancedNonce: let advancedNonce):
      guard let provider = self.session.externalProvider else {
        return
      }
      var paramGasLimit = gasLimit
      if let unwrap = advancedGasLimit, let customGasLimit = BigInt(unwrap) {
        paramGasLimit = customGasLimit
      }
      provider.transferNFT(from: self.currentWallet.address, to: address, item: nftItem, category: nftCategory, gasLimit: paramGasLimit, gasPrice: gasPrice, amount: amount, isERC721: isSupportERC721, advancedPriorityFee: advancedPriorityFee, advancedMaxfee: advancedMaxFee, advancedNonce: advancedNonce) { [weak self] sendResult in
        guard let `self` = self else { return }
        self.navigationController.hideLoading()
        switch sendResult {
        case .success(let result):
          historyTransaction.hash = result.0
          historyTransaction.time = Date()
          historyTransaction.nonce = provider.minTxCount
          historyTransaction.transactionObject = result.1?.toSignTransactionObject()
          historyTransaction.eip1559Transaction = result.2
          provider.minTxCount += 1
          EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
          self.openTransactionStatusPopUp(transaction: historyTransaction)
          controller.dismiss(animated: true, completion: nil)
        case .failure(let error):
          self.confirmVC?.resetActionButtons()
          KNNotificationUtil.postNotification(
            for: kTransactionDidUpdateNotificationKey,
            object: error,
            userInfo: nil
          )
        }
      }
    }
  }
}

// MARK: Network requests
extension KNSendTokenViewCoordinator {
  
  fileprivate func sendSPLTokens(walletAddress: String, privateKeyData: Data, receiptAddress: String, tokenAddress: String, amount: UInt64, recentBlockHash: String, decimals: UInt32, completion: @escaping (String?) -> Void) {
    
    
    SolanaUtil.getTokenAccountsByOwner(ownerAddress: walletAddress, tokenAddress: tokenAddress) { senderTokenAddress in
      guard let senderTokenAddress = senderTokenAddress else {
        completion(nil)
        return
      }
      SolanaUtil.getTokenAccountsByOwner(ownerAddress: receiptAddress, tokenAddress: tokenAddress) { recipientTokenAddress in
        guard let recipientTokenAddress = recipientTokenAddress else {
          completion(nil)
          return
        }
        
        let signedEncodedString = SolanaUtil.signTokenTransferTransaction(tokenMintAddress: tokenAddress, senderTokenAddress: senderTokenAddress, privateKeyData: privateKeyData, recipientTokenAddress: recipientTokenAddress, amount: amount, recentBlockhash: recentBlockHash, tokenDecimals: decimals)
        
        SolanaUtil.sendSignedTransaction(signedTransaction: signedEncodedString) { signature in
          guard let signature = signature else {
            completion(nil)
            return
          }
          completion(signature)
        }
      }
    }
    
    
    
    
    
  }
  
  fileprivate func sendSOL(privateKeyData: Data, receiptAddress: String, amount: UInt64, recentBlockHash: String, decimals: UInt32, completion: @escaping (String?) -> Void) {
    let signedEncodedString = SolanaUtil.signTransferTransaction(privateKeyData: privateKeyData, recipient: receiptAddress, value: amount, recentBlockhash: recentBlockHash)
    SolanaUtil.sendSignedTransaction(signedTransaction: signedEncodedString) { signature in
      guard let signature = signature else {
        completion(nil)
        return
      }
      completion(signature)
    }
  }
  
  fileprivate func getTransactionStatus(signature: String?, historyTransaction: InternalHistoryTransaction) {
    guard let signature = signature else {
      return
    }
    SolanaUtil.getTransactionStatus(signature: signature) { state in
      historyTransaction.hash = signature
      historyTransaction.state = state
      let controller = KNTransactionStatusPopUp(transaction: historyTransaction)
      controller.delegate = self
      self.navigationController.present(controller, animated: true, completion: nil)
      self.transactionStatusVC = controller
    }
  }
  
  fileprivate func didConfirmSolTransfer(_ transaction: UnconfirmedSolTransaction, _ historyTransaction: InternalHistoryTransaction) {
      SolanaUtil.getRecentBlockhash { blockHash in
        let receiptAddress = transaction.to
        
        let seeds = "novel census nominee cover consider again feel obey wool misery fatal use"
        let privateKey = SolanaUtil.seedsToPrivateKey(seeds)
        let privateKeyData = privateKey.data
        let privateKeyString = Base58.encodeNoCheck(data: privateKeyData)

        let signedEncodedString = SolanaUtil.signTransferTransaction(privateKeyData: privateKeyData, recipient: receiptAddress, value: UInt64(transaction.value), recentBlockhash: blockHash)
        
        // send solana
//        self.sendSOL(privateKeyData: privateKeyData, receiptAddress: receiptAddress, amount: UInt64(transaction.value), recentBlockHash: blockHash, decimals: 9) { signature in
//          self.getTransactionStatus(signature: signature, historyTransaction: historyTransaction)
//        }
        
        // send SPL tokens
        
        
        let walletAddress = self.session.wallet.addressString
        self.sendSPLTokens(walletAddress: walletAddress, privateKeyData: privateKeyData, receiptAddress: receiptAddress, tokenAddress: transaction.mintTokenAddress ?? "", amount: UInt64(transaction.value), recentBlockHash: blockHash, decimals: UInt32(transaction.decimal ?? 0)) { signature in
          self.getTransactionStatus(signature: signature, historyTransaction: historyTransaction)
        }
        

      }
  }
  
  
  fileprivate func didConfirmTransfer(_ transaction: UnconfirmedTransaction, historyTransaction: InternalHistoryTransaction) {
    guard let provider = self.session.externalProvider else {
      return
    }
    self.rootViewController?.coordinatorSendTokenUserDidConfirmTransaction()
    // send transaction request
    provider.transfer(transaction: transaction, completion: { [weak self] sendResult in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch sendResult {
      case .success(let result):

        historyTransaction.hash = result.0
        historyTransaction.time = Date()
        historyTransaction.nonce = Int(provider.minTxCount - 1)
        historyTransaction.transactionObject = result.1?.toSignTransactionObject()
        historyTransaction.toAddress = transaction.to?.description
        historyTransaction.eip1559Transaction = result.2

        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
        self.openTransactionStatusPopUp(transaction: historyTransaction)
        self.rootViewController?.coordinatorSuccessSendTransaction()
      case .failure(let error):
        self.confirmVC?.resetActionButtons()
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
        var errorMessage = error.description
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
            errorMessage = message
          }
        }
        self.navigationController.showTopBannerView(message: errorMessage)
        self.navigationController.hideLoading()
      }
    })
  }

  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }
}

extension KNSendTokenViewCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .send(let address) = event {
        self.rootViewController?.coordinatorSend(to: address)
      }
    }
  }
}

extension KNSendTokenViewCoordinator: KNListContactViewControllerDelegate {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .select(let contact) = event {
        self.rootViewController?.coordinatorDidSelectContact(contact)
        self.sendNFTController?.coordinatorDidSelectContact(contact)
      } else if case .send(let address) = event {
        self.rootViewController?.coordinatorSend(to: address)
        self.sendNFTController?.coordinatorSend(to: address)
      }
    }
  }
}

extension KNSendTokenViewCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    self.transactionStatusVC = nil
    switch action {
    case .swap:
      KNNotificationUtil.postNotification(for: kOpenExchangeTokenViewKey)
    case .speedUp(let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .openLink(let url):
      self.navigationController.openSafari(with: url)
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

    viewModel.isSpeedupMode = true
    viewModel.transaction = transaction
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    self.gasPriceSelector = vc
    self.navigationController.present(vc, animated: true, completion: nil)
    /*
    if KNGeneralProvider.shared.isUseEIP1559 {
      if let eipTx = transaction.eip1559Transaction,
         let gasLimitBigInt = BigInt(eipTx.gasLimit.drop0x, radix: 16),
         let maxPriorityBigInt = BigInt(eipTx.maxInclusionFeePerGas.drop0x, radix: 16),
         let maxGasFeeBigInt = BigInt(eipTx.maxGasFee.drop0x, radix: 16) {
        let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: false, gasLimit: gasLimitBigInt, selectType: .custom)
        viewModel.updateGasPrices(
          fast: KNGasCoordinator.shared.fastKNGas,
          medium: KNGasCoordinator.shared.standardKNGas,
          slow: KNGasCoordinator.shared.lowKNGas,
          superFast: KNGasCoordinator.shared.superFastKNGas
        )
        viewModel.advancedGasLimit = gasLimitBigInt.description
        viewModel.advancedMaxPriorityFee = maxPriorityBigInt.shortString(units: UnitConfiguration.gasPriceUnit)
        viewModel.advancedMaxFee = maxGasFeeBigInt.shortString(units: UnitConfiguration.gasPriceUnit)
        viewModel.isSpeedupMode = true
        viewModel.transaction = transaction
        let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
        vc.delegate = self
        self.navigationController.present(vc, animated: true, completion: nil)
        self.gasPriceSelector = vc
      }
    } else {
      let viewModel = SpeedUpCustomGasSelectViewModel(transaction: transaction)
      let controller = SpeedUpCustomGasSelectViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      navigationController.present(controller, animated: true)
    }
    */
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

extension KNSendTokenViewCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      if self.sendNFTController != nil {
        self.sendNFTController?.coordinatorDidUpdateGasPriceType(type, value: value)
      } else {
        self.rootViewController?.coordinatorDidUpdateGasPriceType(type, value: value)
      }
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
      if self.sendNFTController != nil {
        self.sendNFTController?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
      } else {
        self.rootViewController?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
      }
    case .updateAdvancedNonce(nonce: let nonce):
      if self.sendNFTController != nil {
        self.sendNFTController?.coordinatorDidUpdateAdvancedNonce(nonce)
      } else {
        self.rootViewController?.coordinatorDidUpdateAdvancedNonce(nonce)
      }
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

extension KNSendTokenViewCoordinator: WalletsListViewControllerDelegate {
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
      guard let wal = self.session.keystore.matchWithWalletObject(wallet) else {
        return
      }
      self.delegate?.sendTokenViewCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.sendTokenCoordinatorDidSelectAddWallet()
    }
  }
}

extension KNSendTokenViewCoordinator: SpeedUpCustomGasSelectDelegate {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent) {
    switch event {
    case .done(let transaction, let newValue):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
        savedTx?.state = .speedup
        if let speedupTx = transaction.transactionObject?.toSpeedupTransaction(account: account, gasPrice: newValue) {
          speedupTx.send(provider: provider) { (result) in
            switch result {
            case .success(let hash):
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
        if let speedupTx = transaction.eip1559Transaction?.toSpeedupTransaction(gasPrice: newValue), let data = provider.signContractGenericEIP1559Transaction(speedupTx) {
          KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
            switch sendResult {
            case .success(let hash):
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
      } else {
        self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
      }
    case .invaild:
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "your.gas.must.be.10.percent.higher".toBeLocalised(),
        time: 1.5
      )
    }
  }
}

extension KNSendTokenViewCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction) {
    if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
      let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
      
      if let cancelTx = transaction.transactionObject?.toCancelTransaction(account: account) {
        saved?.state = .cancel
        saved?.type = .transferETH
        saved?.transactionSuccessDescription = "-0 ETH"
        cancelTx.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            saved?.hash = hash
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
      
      if let cancelTx = transaction.eip1559Transaction?.toCancelTransaction(), let data = provider.signContractGenericEIP1559Transaction(cancelTx) {
        saved?.state = .cancel
        saved?.type = .transferETH
        saved?.transactionSuccessDescription = "-0 ETH"
        print("[EIP1559] cancel tx \(cancelTx)")
        print("[EIP1559] cancel hex tx \(data.hexString)")
        KNGeneralProvider.shared.sendSignedTransactionData(data, completion: { sendResult in
          switch sendResult {
          case .success(let hash):
            saved?.hash = hash
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
        })
      }
      
    } else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
    }
  }
}

extension KNSendTokenViewCoordinator: QRCodeReaderDelegate {
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
