// Copyright SIX DAY LLC. All rights reserved.

import APIKit
import JSONRPCKit
import BigInt
import TrustKeystore
import TrustCore
import RealmSwift
import KrystalWallets
import AppState

protocol KNSessionDelegate: class {
  func userDidClickExitSession()
}

class KNSession {
  var address: KAddress {
    return AppState.shared.currentAddress
  }
  var web3Swift: Web3Swift?
  var realm: Realm!
  var externalProvider: KNExternalProvider?
  let walletManager = WalletManager.shared
  
  private(set) var transactionStorage: TransactionsStorage!
  private(set) var tokenStorage: KNTokenStorage!

  private(set) var transactionCoordinator: KNTransactionCoordinator?
  var crosschainTxService = CrosschainTransactionService()

  init() {
    self.configureDatabase()
    self.configureWeb3()
    self.configureStorages()
    self.configureProvider()
    self.configureTransactionCoordinator()
  }
  
  func refreshCurrentAddressInfo() {
    guard let address = WalletManager.shared.getAddress(id: address.id) else {
      return
    }
    AppState.shared.currentAddress = address
//    WalletCache.shared.lastUsedAddress = address
//    AppEventCenter.shared.currentAddressUpdated()
    
    AppEventManager.shared.postWalletListUpdatedEvent()
  }
  
  func getCurrentWalletAddresses() -> [KAddress] {
    if address.isWatchWallet {
      return [address]
    }
    return walletManager.getAllAddresses(walletID: address.walletID)
  }
  
  func configureDatabase() {
    let config = RealmConfiguration.configuration(for: address.addressString, chainID: KNGeneralProvider.shared.customRPC.chainID)
    self.realm = try! Realm(configuration: config)
  }
  
  func configureWeb3() {
    self.web3Swift = Web3Factory.shared.web3Instance(forChain: KNGeneralProvider.shared.currentChain)
  }
  
  func configureProvider() {
    if let web3Swift = self.web3Swift {
      self.externalProvider = KNExternalProvider(address: address, web3: web3Swift)
    }
    let pendingTxs = self.transactionStorage.kyberPendingTransactions
    guard let tx = pendingTxs.first(where: { $0.from.lowercased() == address.addressString.lowercased() }) else {
      return
    }
    guard let nonce = Int(tx.nonce) else {
      return
    }
    self.externalProvider?.updateNonceWithLastRecordedTxNonce(nonce)
  }
  
  func configureStorages() {
    self.transactionStorage = TransactionsStorage(realm: realm)
    self.tokenStorage = KNTokenStorage(realm: realm)
  }
  
  func configureTransactionCoordinator() {
    self.transactionCoordinator?.stop()
    self.transactionCoordinator = nil
    self.transactionCoordinator = KNTransactionCoordinator(
      transactionStorage: self.transactionStorage,
      tokenStorage: self.tokenStorage,
      externalProvider: self.externalProvider
    )
    self.transactionCoordinator?.start()
    self.crosschainTxService.scheduleFetchPendingTransaction()
  }
  
  func switchAddress(address: KAddress) {
//    AppEventCenter.shared.switchAddress(address: address)
    WalletCache.shared.lastUsedAddress = address
    self.configureDatabase()
    self.configureWeb3()
    self.configureProvider()
    self.configureStorages()
    self.resetTransactionCoordinator()
  }
  
  func resetTransactionCoordinator() {
    self.crosschainTxService.cancelScheduledFetching()
    self.transactionCoordinator?.stop()
    self.transactionCoordinator = nil
    self.configureTransactionCoordinator()
    self.transactionCoordinator?.start()
    self.crosschainTxService.scheduleFetchPendingTransaction()
  }

  func startSession() {
    self.web3Swift?.start()
    self.transactionCoordinator?.start()
    BalanceStorage.shared.updateCurrentWallet(address)
    EtherscanTransactionStorage.shared.updateCurrentHistoryCache()
  }

  func stopSession() {
    self.crosschainTxService.cancelScheduledFetching()
    self.transactionCoordinator?.stop()
    self.transactionCoordinator = nil

    KNAppTracker.resetAllAppTrackerData()
    let address = walletManager.createEmptyAddress()
    WalletCache.shared.lastUsedAddress = address
  }

  func clearWalletData(wallet: KWallet) {
    let addresses = walletManager.getAllAddresses(walletID: wallet.id)
    addresses.forEach { address in
      KNAppTracker.resetAppTrackerData(for: address.addressString)
      for _ in KNEnvironment.allEnvironments() {
        let config = RealmConfiguration.configuration(for: address.addressString, chainID: KNGeneralProvider.shared.customRPC.chainID)
        let realm = try! Realm(configuration: config)
        let transactionStorage = TransactionsStorage(realm: realm)
        transactionStorage.deleteAll()
        let tokenStorage = KNTokenStorage(realm: realm)
        tokenStorage.deleteAll()
        
        let globalConfig = RealmConfiguration.globalConfiguration()
        let globalRealm = try! Realm(configuration: globalConfig)
        if let walletObject = globalRealm.object(ofType: KNWalletObject.self, forPrimaryKey: address.addressString) {
          KNWalletPromoInfoStorage.shared.removeWalletPromoInfo(address: walletObject.address)
          try! globalRealm.write { globalRealm.delete(walletObject) }
        }
      }
    }
  }

  func addNewPendingTransaction(_ transaction: Transaction) {
    // Put here to be able force update new pending transaction immmediately
    let kyberTx = KNTransaction.from(transaction: transaction)
    self.transactionStorage.addKyberTransactions([kyberTx])
    self.transactionCoordinator?.updatePendingTransaction(kyberTx)
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
  }

  func updatePendingTransactionWithHash(hashTx: String,
                                        ultiTransaction: Transaction,
                                        state: TransactionState = .cancelling,
                                        completion: @escaping () -> Void = {}) {
    if transactionStorage.updateKyberTransaction(forPrimaryKey: hashTx, state: state) {
      self.addNewPendingTransaction(ultiTransaction)
      completion()
    }
  }

  func updateFailureTransaction(type: TransactionType) -> Bool {
    var hashTx = ""
    switch type {
    case .speedup:
      hashTx = transactionStorage.kyberSpeedUpProcessingTransactions.first?.id ?? ""
    case .cancel:
      hashTx = transactionStorage.kyberCancelProcessingTransactions.first?.id ?? ""
    default:
      return false
    }
    guard !hashTx.isEmpty else {
      return false
    }
    if isDebug { print("[Debug] call update original tx \(hashTx)") }
    if transactionStorage.updateKyberTransaction(forPrimaryKey: hashTx, state: .pending) {
      guard let transaction = transactionStorage.getKyberTransaction(forPrimaryKey: hashTx), transaction.isInvalidated == false else { return false }
      self.transactionCoordinator?.updatePendingTransaction(transaction)
      KNNotificationUtil.postNotification(
        for: kTransactionDidUpdateNotificationKey,
        object: transaction.id,
        userInfo: nil
      )
    }
    return true
  }

  static func resumeInternalSession() {
    KNRateCoordinator.shared.resume()
    if KNGeneralProvider.shared.currentChain == .solana {
      SolFeeCoordinator.shared.resume()
    } else {
      KNGasCoordinator.shared.resume()
    }
    KNRecentTradeCoordinator.shared.resume()
    KNSupportedTokenCoordinator.shared.resume()
//    KNNotificationCoordinator.shared.resume()
  }

  static func pauseInternalSession() {
    KNRateCoordinator.shared.pause()
    KNGasCoordinator.shared.pause()
    KNRecentTradeCoordinator.shared.pause()
    KNSupportedTokenCoordinator.shared.pause()
//    KNNotificationCoordinator.shared.pause()
  }
}

extension KNSession {
  var sessionID: String {
    return KNSession.sessionID(from: address.addressString)
  }

  static func sessionID(from address: String) -> String {
    if KNEnvironment.default == .production {
      return "sessionID-\(address)"
    }
    return "sessionID-\(KNEnvironment.default.displayName)-\(address)"
  }
}
