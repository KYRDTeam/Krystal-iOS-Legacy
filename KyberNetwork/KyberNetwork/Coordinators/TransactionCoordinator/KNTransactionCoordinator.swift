// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import APIKit
import JSONRPCKit
import JavaScriptKit
import Result
import BigInt
import Moya
import Sentry
import KrystalWallets
import AppState
import TransactionModule

class KNTransactionCoordinator {

  let transactionStorage: TransactionsStorage
  let tokenStorage: KNTokenStorage
  let externalProvider: KNExternalProvider?

  lazy var addressToSymbol: [String: String] = {
    var maps: [String: String] = [:]
    KNSupportedTokenStorage.shared.supportedTokens.forEach({
      maps[$0.contract.lowercased()] = $0.symbol
    })
    return maps
  }()
  fileprivate var isLoadingEnabled: Bool = false

  fileprivate var pendingTxTimer: Timer?
  fileprivate var tokenTxTimer: Timer?
  var address: KAddress {
    return AppState.shared.currentAddress
  }
  deinit { self.stop() }

  init(
    transactionStorage: TransactionsStorage,
    tokenStorage: KNTokenStorage,
    externalProvider: KNExternalProvider?
  ) {
    self.transactionStorage = transactionStorage
    self.tokenStorage = tokenStorage
    self.externalProvider = externalProvider
  }

  func start(isReloadData: Bool = true) {
    self.isLoadingEnabled = true
    if isReloadData && KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() { self.startUpdatingCompletedTransactions()
    }
    self.startUpdatingPendingTransactions()

    // remove some old txs
    let oldKyberTxs = self.transactionStorage.kyberMinedTransactions.filter({ return Date().timeIntervalSince($0.date) >= 7.0 * 24.0 * 60.0 * 60.0 })
    self.transactionStorage.delete(oldKyberTxs)
  }

  func stop() {
    self.isLoadingEnabled = false
    self.stopUpdatingPendingTransactions()
    self.stopUpdatingCompletedTransaction()
  }

  func forceUpdateNewTransactionsWhenPendingTxCompleted() {
    self.isLoadingEnabled = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
      if self.isLoadingEnabled {
        self.loadEtherscanTransactions()
      }
    }
  }
}

// MARK: ETH/ERC20 Token transactions
extension KNTransactionCoordinator {
  func startUpdatingCompletedTransactions() {
    self.tokenTxTimer?.invalidate()
    self.loadEtherscanTransactions()
    self.tokenTxTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.minutes2,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        if self.isLoadingEnabled {
          self.loadEtherscanTransactions(isInit: !EtherscanTransactionStorage.shared.isSavedKrystalHistory())
        }
      }
    )
  }

  func stopUpdatingCompletedTransaction() {
    self.tokenTxTimer?.invalidate()
    self.tokenTxTimer = nil
  }

  fileprivate func loadKrystalHistory(isInit: Bool = false) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let lastBlock = EtherscanTransactionStorage.shared.getKrystalHistoryTransactionStartBlock()

    provider.requestWithFilter(.getTransactionsHistory(address: address.addressString, lastBlock: isInit ? "0" : lastBlock)) { result in
      if case .success(let resp) = result {
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(HistoryResponse.self, from: resp.data)
          let history = data.transactions
          var needReloadUI = false
          if lastBlock.isEmpty || isInit {
            EtherscanTransactionStorage.shared.setKrystalTransaction(history, isSave: isInit)
            needReloadUI = true
          } else {
            needReloadUI = EtherscanTransactionStorage.shared.appendKrystalTransaction(history)
          }
          if needReloadUI {
            DispatchQueue.main.async {
              KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
            }
          }
          print("[GetHistoryTransaction][Success]")
        } catch let error {
          print("[GetHistoryTransaction][Error] \(error.localizedDescription)")
        }
      } else {
      }
    }
  }

  func loadEtherscanTransactions(isInit: Bool = false) {
    DispatchQueue.global(qos: .background).async {
      self.loadKrystalHistory(isInit: isInit)
    }
  }

  func fetchListERC20TokenTransactions(
    forAddress address: String,
    startBlock: Int,
    completion: ((Result<[EtherscanTokenTransaction], AnyError>) -> Void)?
    ) {
    if isDebug { print("---- ERC20 Token Transactions: Fetching ----") }
    let provider = MoyaProvider<KNEtherScanService>()
    let service = KNEtherScanService.getListTokenTransactions(
      address: address,
      startBlock: startBlock
    )
    DispatchQueue.global(qos: .background).async {
      provider.requestWithFilter(service) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              _ = try response.filterSuccessfulStatusCodes()
              let decoder = JSONDecoder()
              do {
                let result = try decoder.decode(TokenTransactionListResponse.self, from: response.data)
                completion?(.success(result.result))
              } catch let error {
                completion?(.failure(AnyError(error)))
              }
            } catch let error {
              completion?(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion?(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  // Fetch all transactions, but extract only send ETH transactions
  fileprivate func fetchAllTransactions(forAddress address: String, startBlock: Int, completion: ((Result<[EtherscanTransaction], AnyError>) -> Void)?) {
    if isDebug { print("---- All Token Transactions: Fetching ----") }
    let provider = MoyaProvider<KNEtherScanService>()
    let service = KNEtherScanService.getListTransactions(address: address, startBlock: startBlock)
    DispatchQueue.global(qos: .background).async {
      provider.requestWithFilter(service) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              _ = try response.filterSuccessfulStatusCodes()
              let decoder = JSONDecoder()
              do {
                let result = try decoder.decode(TransactionsListResponse.self, from: response.data)
                completion?(.success(result.result))
              } catch let error {
                completion?(.failure(AnyError(error)))
              }
            } catch let error {
              completion?(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion?(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  // Load internal transaction for receiving ETH only
  fileprivate func fetchInternalTransactions(forAddress address: String, startBlock: Int, completion: ((Result<[EtherscanInternalTransaction], AnyError>) -> Void)?) {
    if isDebug { print("---- Internal Token Transactions: Fetching ----") }
    let provider = MoyaProvider<KNEtherScanService>()
    let service = KNEtherScanService.getListInternalTransactions(address: address, startBlock: startBlock)
    DispatchQueue.global(qos: .background).async {
      provider.requestWithFilter(service) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              _ = try response.filterSuccessfulStatusCodes()
              let decoder = JSONDecoder()
              do {
                let result = try decoder.decode(InternalListResponse.self, from: response.data)
                completion?(.success(result.result))
              } catch let error {
                completion?(.failure(AnyError(error)))
              }

            } catch let error {
              completion?(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion?(.failure(AnyError(error)))
          }
        }
      }
    }
  }
  
  fileprivate func fetchNFTTransactions(forAddress address: String, startBlock: Int, completion: ((Result<[NFTTransaction], AnyError>) -> Void)?) {
    if isDebug { print("---- NFT Transactions: Fetching ----") }
    let provider = MoyaProvider<KNEtherScanService>()
    let service = KNEtherScanService.getNFTTransaction(address: address, startBlock: startBlock)
    DispatchQueue.global(qos: .background).async {
      provider.requestWithFilter(service) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              _ = try response.filterSuccessfulStatusCodes()
              let decoder = JSONDecoder()
              do {
                let result = try decoder.decode(NFTHistoryResponse.self, from: response.data)
                completion?(.success(result.result))
              } catch let error {
                completion?(.failure(AnyError(error)))
              }

            } catch let error {
              completion?(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion?(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  fileprivate func updateAllTransactions(address: String, data: [JSONDictionary]) -> [Transaction] {
    let eth = KNSupportedTokenStorage.shared.ethToken

    let completedTransactions: [Transaction] = data.filter({ return ($0["isError"] as? String ?? "") == "0" })
      .map({ return KNTokenTransaction(internalDict: $0, eth: eth) })
      .filter({ return $0.tokenSymbol.lowercased() == eth.symbol.lowercased() })
      .map({ return $0.toTransaction() })
    let failedTransactions: [Transaction] = data.filter({ return ($0["isError"] as? String ?? "") == "1"
    }).map({
      let transaction = KNTokenTransaction(internalDict: $0, eth: eth).toTransaction()
      transaction.internalState = TransactionState.error.rawValue
      return transaction
    })
    var transactions = completedTransactions
    transactions.append(contentsOf: failedTransactions)
    self.updateListTokenTransactions(transactions)
    return transactions
  }

  func updateListTokenTransactions(_ transactions: [Transaction]) {
    if transactions.isEmpty { return }
    self.handleReceiveEtherOrToken(transactions)
    self.transactionStorage.add(transactions)
    KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
    var tokenObjects: [TokenObject] = []
    let savedTokens: [TokenObject] = self.tokenStorage.tokens
    transactions.forEach { tx in
      // receive token tx only
      if !tx.isInvalidated, address.addressString == tx.to.lowercased(),
        let token = tx.getTokenObject(), !tokenObjects.contains(token),
        !savedTokens.contains(token) {
        tokenObjects.append(token)
      }
    }
    if !tokenObjects.isEmpty {
      self.tokenStorage.add(tokens: tokenObjects)
      KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    }
  }

  fileprivate func handleReceiveEtherOrToken(_ transactions: [Transaction]) {
    guard !transactions.isEmpty else { return }
    let addressString = address.addressString
    if KNAppTracker.transactionLoadState(for: addressString) != .done { return }
    let receivedTxs = transactions.filter({ return $0.to.lowercased() == addressString && $0.state == .completed }).sorted(by: { return $0.date > $1.date })
    // last transaction is received, and less than 5 mins ago
    if let latestReceiveTx = receivedTxs.first, Date().timeIntervalSince(latestReceiveTx.date) <= 5.0 * 60.0 {
      let title = NSLocalizedString("received.token", value: "Received %@", comment: "")
      let message = NSLocalizedString("successfully.received", value: "Successfully received %@ from %@", comment: "")
      if self.transactionStorage.getKyberTransaction(forPrimaryKey: latestReceiveTx.id) != nil { return } // swap/transfer transaction
      if self.transactionStorage.get(forPrimaryKey: latestReceiveTx.compoundKey) != nil { return } // already done transaction
      let address = "\(latestReceiveTx.from.prefix(12))...\(latestReceiveTx.from.suffix(10))"

      guard let symbol = latestReceiveTx.getTokenSymbol() else { return }
      let amount = "\(latestReceiveTx.value) \(symbol)"
      let userInfo = ["transaction_hash": "\(latestReceiveTx.id)"]

      KNNotificationUtil.localPushNotification(
        title: String(format: title, symbol),
        body: String(format: message, arguments: [amount, address]),
        userInfo: userInfo
      )
    }
  }
}

// MARK: Pending transactions
extension KNTransactionCoordinator {
  func startUpdatingPendingTransactions() {
    self.pendingTxTimer?.invalidate()
    self.pendingTxTimer = nil
    self.shouldCheckInternalHistory()
    var interval: TimeInterval
    switch KNGeneralProvider.shared.currentChain {
    case .eth:
      interval = 15.0
    case .solana:
      interval = 3.0
    default:
      interval = 8.0
    }
    self.pendingTxTimer = Timer.scheduledTimer(
      withTimeInterval: interval,
      repeats: true,
      block: { [weak self] timer in
        guard let `self` = self else { return }
        self.shouldCheckInternalHistory()
      }
    )
  }
  
  func updatePendingTransaction(_ transaction: KNTransaction) {
    if transaction.isInvalidated { return }
    self.checkTransactionReceipt(transaction) { [weak self] error in
      if error == nil { return }
      guard let `self` = self else { return }
      if transaction.isInvalidated { return }
      self.externalProvider?.getTransactionByHash(transaction.id, completion: { [weak self] _, sessionError in
        guard let `self` = self else { return }
        guard let trans = self.transactionStorage.getKyberTransaction(forPrimaryKey: transaction.id) else { return }
        if trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        //recep fail = success
        // by hash success = pending
        if trans.isInvalidated { return }
        if let error = sessionError {
          // Failure
          if case .responseError(let err) = error, let respError = err as? JSONRPCError {
            switch respError {
            case .responseError(let code, let message, _):
              if isDebug { NSLog("Fetch pending transaction with hash \(transaction.id) failed with error code \(code) and message \(message)") }
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: respError,
                userInfo: nil
              )
              self.transactionStorage.delete([trans])
            case .resultObjectParseError:
              // transaction seems to be removed
              if transaction.date.addingTimeInterval(600) < Date() {
                self.removeTransactionHasBeenLost(transaction)
              }
            default: break
            }
          }
        }
        if transaction.date.addingTimeInterval(60) < Date() {
          let minedTxs = self.transactionStorage.transferNonePendingObjects
          if let tx = minedTxs.first(where: { $0.from.lowercased() == self.address.addressString }), let nonce = Int(tx.nonce), let txNonce = Int(transaction.nonce) {
            if nonce >= txNonce && tx.id.lowercased() != transaction.id.lowercased() {
              self.removeTransactionHasBeenLost(transaction)
            }
          }
        }
      })
    }
  }

  fileprivate func checkTransactionReceipt(_ transaction: KNTransaction, completion: @escaping (Error?) -> Void) {
    self.externalProvider?.getReceipt(for: transaction) { [weak self] result in
      switch result {
      case .success(let newTx):
        if let trans = self?.transactionStorage.getKyberTransaction(forPrimaryKey: transaction.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        if newTx.isInvalidated { return }
        self?.transactionStorage.addKyberTransactions([newTx])
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: newTx.id,
          userInfo: nil
        )
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }
  
  //MARK: NEW IMPLEMENTATION
  fileprivate func shouldCheckInternalHistory() {
    guard let transaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().last, self.isLoadingEnabled else {
      return
    }
    if transaction.state == .pending {
      self.checkInternalHistory(transaction)
    }
  }
  
  fileprivate func checkInternalHistory(_ transaction: InternalHistoryTransaction) {
    if KNGeneralProvider.shared.currentChain == .solana {
      let signature = transaction.hash
      SolanaUtil.getTransactionStatus(signature: signature) { state in
        guard let state = state else {
          return
        }
        transaction.state = state
        if state == .done || state == .error {
          EtherscanTransactionStorage.shared.removeInternalHistoryTransactionWithHash(transaction.hash)
          KNNotificationUtil.postNotification(
            for: kTransactionDidUpdateNotificationKey,
            object: transaction,
            userInfo: nil
          )
            TransactionManager.onTransactionStatusUpdated(hash: transaction.txHash, status: state)
        }
      }
    } else {
      self.externalProvider?.getReceipt(hash: transaction.hash, completion: { [weak self] (result) in
        guard let `self` = self else { return }
        switch result {
        case .success(let receipt):
          transaction.state = receipt.status == "1" ? .done : .error
          if KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
            EtherscanTransactionStorage.shared.removeInternalHistoryTransactionWithHash(transaction.hash)
          } else {
            EtherscanTransactionStorage.shared.updateInternalHistoryTransactionForUnsupportedChain(transaction)
          }
          
          KNNotificationUtil.postNotification(
            for: kTransactionDidUpdateNotificationKey,
            object: transaction,
            userInfo: nil
          )
            TransactionManager.onTransactionStatusUpdated(hash: transaction.txHash, status: transaction.state)
        case .failure:
          self.externalProvider?.getTransactionByHash(transaction.hash, completion: { pendingTransaction, error in
            if case .responseError(let err) = error, let respError = err as? JSONRPCError {
              switch respError {
  //            case .responseError:
  //              transaction.state = .error
  //              if KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
  //                EtherscanTransactionStorage.shared.removeInternalHistoryTransactionWithHash(transaction.hash)
  //              } else {
  //                EtherscanTransactionStorage.shared.updateInternalHistoryTransactionForUnsupportedChain(transaction)
  //              }
  //              KNNotificationUtil.postNotification(
  //                for: kTransactionDidUpdateNotificationKey,
  //                object: transaction,
  //                userInfo: nil
  //              )
              case .resultObjectParseError:
                guard transaction.time.addingTimeInterval(900) < Date() else {
                  return
                }
                transaction.state = .drop
                if KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
                  EtherscanTransactionStorage.shared.removeInternalHistoryTransactionWithHash(transaction.hash)
                } else {
                  EtherscanTransactionStorage.shared.updateInternalHistoryTransactionForUnsupportedChain(transaction)
                }
                KNNotificationUtil.postNotification(
                  for: kTransactionDidUpdateNotificationKey,
                  object: transaction,
                  userInfo: nil
                )
                  TransactionManager.onTransactionStatusUpdated(hash: transaction.txHash, status: transaction.state)
              default: break
              }
            }
          })
        }
      })
    }
  }

  fileprivate func removeTransactionHasBeenLost(_ transaction: KNTransaction) {
    guard let trans = self.transactionStorage.getKyberTransaction(forPrimaryKey: transaction.id), trans.state == .pending else { return }
    let id = trans.id
    let type = trans.type
    let userInfo: [String: TransactionType] = [Constants.transactionIsLost: type]
    self.transactionStorage.delete([trans])
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: id,
      userInfo: userInfo
    )
  }

  func stopUpdatingPendingTransactions() {
    self.pendingTxTimer?.invalidate()
    self.pendingTxTimer = nil
  }
}

extension RawTransaction {
  static func from(dictionary: JSONDictionary) -> RawTransaction {
    let id: String = dictionary["hash"] as? String ?? ""
    let blockNumber = Int(dictionary["blockNumber"] as? String ?? "0") ?? 0
    let from: String = dictionary["from"] as? String ?? ""
    let to: String = dictionary["to"] as? String ?? ""
    let value: String = dictionary["value"] as? String ?? ""
    let gas: String = dictionary["gas"] as? String ?? ""
    let gasPrice: String = dictionary["gasPrice"] as? String ?? ""
    let gasUsed: String = dictionary["gasUsed"] as? String ?? ""
    let nonce: Int = Int(dictionary["nonce"] as? String ?? "0") ?? 0
    let timeStamp: String = dictionary["timeStamp"] as? String ?? ""
    let input: String = dictionary["input"] as? String ?? ""
    let isError: String? = dictionary["isError"] as? String

    return RawTransaction(
      hash: id,
      blockNumber: blockNumber,
      timeStamp: timeStamp,
      nonce: nonce,
      from: from,
      to: to,
      value: value,
      gas: gas,
      gasPrice: gasPrice,
      input: input,
      gasUsed: gasUsed,
      error: isError == "0" ? nil : isError,
      operations: nil
    )
  }
}

// MARK: Transaction Storage Extension
extension TransactionsStorage {

  var nonePendingObjects: [Transaction] {
    return objects.filter({ return $0.state != .pending })
  }

  var transferNonePendingObjects: [Transaction] {
    return objects.filter({ return $0.state != .pending && $0.isTransfer })
  }

  func addHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    if self.realm.objects(KNHistoryTransaction.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add(transactions, update: .modified)
    try! realm.commitWrite()
  }

  func deleteHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    if self.realm.objects(KNHistoryTransaction.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(transactions)
    try! self.realm.commitWrite()
  }

  func deleteAllHistoryTransactions() {
    if self.realm.objects(KNHistoryTransaction.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(self.realm.objects(KNHistoryTransaction.self))
    try! self.realm.commitWrite()
  }

  var historyTransactions: [KNHistoryTransaction] {
    if self.realm.objects(KNHistoryTransaction.self).isInvalidated { return [] }
    return self.realm.objects(KNHistoryTransaction.self)
      .sorted(byKeyPath: "blockTimestamp", ascending: false)
      .filter { return !$0.id.isEmpty }
  }
}
