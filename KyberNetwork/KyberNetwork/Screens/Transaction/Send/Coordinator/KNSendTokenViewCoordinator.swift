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
import KrystalWallets

protocol KNSendTokenViewCoordinatorDelegate: class {
  func sendTokenViewCoordinatorSelectOpenHistoryList()
  func sendTokenCoordinatorDidSelectManageWallet()
  func sendTokenCoordinatorDidSelectAddWallet()
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject)
  func sendTokenCoordinatorDidClose()
  func sendTokenCoordinatorDidSelectAddChainWallet(chainType: ChainType)
}

class KNSendTokenViewCoordinator: NSObject, Coordinator {
  weak var delegate: KNSendTokenViewCoordinatorDelegate?
  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  var balances: [String: Balance] = [:]
  fileprivate var from: TokenObject
  fileprivate var nftItem: NFTItem = NFTItem()
  fileprivate var nftCategory: NFTSection = NFTSection(collectibleName: "", collectibleAddress: "", collectibleSymbol: "", collectibleLogo: "", items: [])

  var rootViewController: KSendTokenViewController?
  
  var sendNFTController: SendNFTViewController?

  fileprivate(set) var searchTokensVC: KNSearchTokenViewController?
  fileprivate(set) var confirmVC: KConfirmSendViewController?
  fileprivate(set) weak var gasPriceSelector: GasFeeSelectorPopupViewController?
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  let sendNFT: Bool
  fileprivate var isSupportERC721 = true
  
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  var web3Service: EthereumWeb3Service {
    return KNGeneralProvider.shared.web3Service
  }

  lazy var addContactVC: KNNewContactViewController = {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: "")
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var multiSendCoordinator: MultiSendCoordinator = {
    let coordinator = MultiSendCoordinator(navigationController: self.navigationController)
    coordinator.delegate = self.delegate
    return coordinator
  }()

  deinit {
    self.rootViewController?.removeObserveNotification()
  }

  init(
    navigationController: UINavigationController,
    balances: [String: Balance],
    from: TokenObject = KNGeneralProvider.shared.quoteTokenObject,
    sendNFT: Bool = false
  ) {
    self.navigationController = navigationController
    self.balances = balances
    self.from = from
    self.sendNFT = sendNFT
  }
  
  init(
    navigationController: UINavigationController,
    nftItem: NFTItem,
    supportERC721: Bool,
    nftCategory: NFTSection,
    sendNFT: Bool = false
  ) {
    self.navigationController = navigationController
    self.nftItem = nftItem
    self.nftCategory = nftCategory
    self.from = KNGeneralProvider.shared.quoteTokenObject
    self.isSupportERC721 = supportERC721
    self.sendNFT = sendNFT
  }

  func start() {
    if sendNFT {
      let controller = SendNFTViewController(viewModel: SendNFTViewModel(item: self.nftItem, category: self.nftCategory, supportERC721: self.isSupportERC721))
      controller.delegate = self
      self.sendNFTController = controller
      self.navigationController.pushViewController(controller, animated: true)
    } else {
      let viewModel = KNSendTokenViewModel(
        from: self.from,
        balances: self.balances,
        currentAddress: currentAddress.addressString
      )
      let controller = KSendTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true)
      self.rootViewController = controller
      self.rootViewController?.coordinatorUpdateBalances(self.balances)
    }
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
  
  func coordinatorAppSwitchAddress() {
    self.rootViewController?.coordinatorAppSwitchAddress()
    self.multiSendCoordinator.appCoordinatorSwitchAddress()
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
      if currentAddress.isWatchWallet {
        self.navigationController.showTopBannerView(message: Strings.watchWalletNotSupportOperation)
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
      self.rootViewController?.coordinatorDidValidateSolTransferTransaction()
    case .send(let transaction, let ens):
      self.openConfirmTransfer(transaction: transaction, ens: ens)
    case .addContact(let address, let ens):
      self.openNewContact(address: address, ens: ens)
    case .openContactList:
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
      let viewModel = WalletsListViewModel()
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
    case .sendNFT(item: let item, category: let category, gasPrice: let gasPrice, gasLimit: let gasLimit, to: let to, amount: let amount, ens: let ens, isERC721: let isSupportERC721, advancedGasLimit: let advancedGasLimit, advancedPriorityFee: let advancedPriorityFee, advancedMaxFee: let advancedMaxFee, advancedNonce: let advancedNonce):
      let vm = ConfirmSendNFTViewModel(nftItem: item, nftCategory: category, gasPrice: gasPrice, gasLimit: gasLimit, address: to, ens: ens, amount: amount, supportERC721: isSupportERC721, advancedGasLimit: advancedGasLimit, advancedMaxPriorityFee: advancedPriorityFee, advancedMaxFee: advancedMaxFee, advancedNonce: advancedNonce)
      let vc = ConfirmSendNFTViewController(viewModel: vm)
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    case .estimateGasLimitTransferNFT(to: let to, item: let item, category: let category, gasPrice: let gasPrice, gasLimit: let gasLimit, amount: let amount, isERC721: let isERC721):
      let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
      web3Service.getEstimateGasLimitForTransferNFT(address: currentAddress.addressString, to: to, categoryAddress: category.collectibleAddress, tokenID: item.tokenID, gasPrice: gasPrice, gasLimit: gasLimit, amount: amount, isERC721: isERC721) { result in
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
    case .addChainWallet(let chainType):
      self.delegate?.sendTokenCoordinatorDidSelectAddChainWallet(chainType: chainType)
    }
  }

  fileprivate func sendGetPreScreeningWalletRequest(completion: @escaping (Result<Moya.Response, MoyaError>) -> Void) {
    let address = currentAddress.addressString
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
    if currentAddress.isWatchWallet {
      return
    }
    let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
    web3Service.getEstimateGasLimit(address: currentAddress.addressString, transferTransaction: transaction) { [weak self] result in
      if case .success(let gasLimit) = result {
        self?.rootViewController?.coordinatorUpdateEstimatedGasLimit(
          gasLimit,
          from: transaction.transferType.tokenObject(),
          address: transaction.to ?? ""
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
    EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain).getTransactionCount(for: currentAddress.addressString) { result in
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
        if currentAddress.isWatchWallet {
          return
        }
        self.didConfirmTransfer(transaction, historyTransaction: historyTransaction)
        controller.dismiss(animated: true, completion: nil)
        self.confirmVC = nil
        self.navigationController.displayLoading()
      }
    case .cancel:
      controller.dismiss(animated: true) {
        self.confirmVC = nil
      }
    case .confirmNFT(nftItem: let nftItem, nftCategory: let nftCategory, gasPrice: let gasPrice, gasLimit: let gasLimit, address: let address, amount: let amount, isSupportERC721: let isSupportERC721, historyTransaction: let historyTransaction, advancedGasLimit: let advancedGasLimit, advancedPriorityFee: let advancedPriorityFee, advancedMaxFee: let advancedMaxFee, advancedNonce: let advancedNonce):
      if currentAddress.isWatchWallet {
        return
      }
      var paramGasLimit = gasLimit
      if let unwrap = advancedGasLimit, let customGasLimit = BigInt(unwrap) {
        paramGasLimit = customGasLimit
      }
      
      self.transferNFT(to: address, item: nftItem, category: nftCategory, gasLimit: paramGasLimit, gasPrice: gasPrice, amount: amount, isERC721: isSupportERC721, advancedPriorityFee: advancedPriorityFee, advancedMaxfee: advancedMaxFee, advancedNonce: advancedNonce) { [weak self] sendResult in
        guard let `self` = self else { return }
        self.navigationController.hideLoading()
        switch sendResult {
        case .success(let result):
          historyTransaction.hash = result.hash
          historyTransaction.time = Date()
          historyTransaction.nonce = result.nonce ?? 0
          historyTransaction.transactionObject = result.transaction
          historyTransaction.eip1559Transaction = result.eip1559Transaction
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
  
  private func transferNFT(to: String, item: NFTItem, category: NFTSection, gasLimit: BigInt, gasPrice: BigInt, amount: Int, isERC721: Bool, advancedPriorityFee: String?, advancedMaxfee: String?, advancedNonce: String?, completion: @escaping (Result<TransferTransactionResultData, AnyError>) -> Void) {
    web3Service.getTransactionCount(for: currentAddress.addressString) { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.web3Service.requestDataForNFTTransfer(from: self.currentAddress.addressString, to: to, tokenID: item.tokenID, amount: amount, isERC721: isERC721) { dataResult in
          switch dataResult {
          case .success(let data):
            let processor: TransactionProcessor = {
              if let unwrapPriorityFee = advancedPriorityFee,
                 let _ = unwrapPriorityFee.shortBigInt(units: UnitConfiguration.gasPriceUnit),
                 let unwrapMaxFee = advancedMaxfee,
                 let _ = unwrapMaxFee.shortBigInt(units: UnitConfiguration.gasPriceUnit) {
                return EthereumEIP1559TransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
              } else {
                return EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
              }
            }()
            processor.transferNFT(transferData: data, from: self.currentAddress, to: to, gasLimit: gasLimit, gasPrice: gasPrice, amount: amount, isERC721: isERC721, collectibleAddress: category.collectibleAddress, advancedPriorityFee: advancedPriorityFee, advancedMaxfee: advancedMaxfee, advancedNonce: advancedNonce, completion: completion)
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  
}

// MARK: Network requests
extension KNSendTokenViewCoordinator {
  
  fileprivate func didConfirmTransfer(_ transaction: UnconfirmedTransaction, historyTransaction: InternalHistoryTransaction) {
    
    let processor: TransactionProcessor = {
      switch KNGeneralProvider.shared.currentChain {
      case .solana:
        return SolanaTransactionProcessor()
      default:
        if transaction.maxInclusionFeePerGas != nil, transaction.maxGasFee != nil {
          return EthereumEIP1559TransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
        } else {
          return EthereumTransactionProcessor(chain: KNGeneralProvider.shared.currentChain)
        }
      }
    }()
    
    processor.transfer(address: currentAddress, transaction: transaction) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let txData):
        historyTransaction.hash = txData.hash
        historyTransaction.time = Date()
        historyTransaction.nonce = txData.nonce ?? 0
        historyTransaction.transactionObject = txData.transaction
        historyTransaction.toAddress = transaction.to
        historyTransaction.tokenAddress = transaction.transferType.tokenObject().address
        historyTransaction.eip1559Transaction = txData.eip1559Transaction

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
    }
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
      guard KNGeneralProvider.shared.currentChain != .klaytn else {
        self.navigationController.showErrorTopBannerMessage(message: "Unsupported action")
        return
      }
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(let tx):
      guard KNGeneralProvider.shared.currentChain != .klaytn else {
        self.navigationController.showErrorTopBannerMessage(message: "Unsupported action")
        return
      }
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

extension KNSendTokenViewCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.sendTokenCoordinatorDidSelectManageWallet()
    case .didSelect(let address):
      return
    case .addWallet:
      self.delegate?.sendTokenCoordinatorDidSelectAddWallet()
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
          with: Strings.invalidSession,
          message: Strings.invalidSessionTryOtherQR,
          time: 1.5
        )
        return
      }

      do {
        let privateKey = try WalletManager.shared.exportPrivateKey(address: self.currentAddress)
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
