//
//  EtherscanTransactionStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/9/21.
//

import Foundation

class HistoryTransactionStorage {
  static let shared = HistoryTransactionStorage()
  private var wallet: Wallet?
  
  private var internalHistoryTransactions: [InternalHistoryTransaction] = []
  private var krystalHistoryTransaction: [KrystalHistoryTransaction] = []
  
  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet

    self.krystalHistoryTransaction = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName, as: [KrystalHistoryTransaction].self) ?? []
    self.internalHistoryTransactions = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName, as: [InternalHistoryTransaction].self) ?? []
  }
  
  func isSavedKrystalHistory() -> Bool {
    guard let unwrapped = self.wallet else {
      return false
    }
    return Storage.isFileExistAtPath(unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName)
  }
  
  func getKrystalTransaction() -> [KrystalHistoryTransaction] {
    return self.krystalHistoryTransaction
  }

  func setKrystalTransaction(_ txs: [KrystalHistoryTransaction], isSave: Bool = true) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.krystalHistoryTransaction = txs
    if isSave {
      Storage.store(self.krystalHistoryTransaction, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName)
    }
  }
  
  func appendKrystalTransaction(_ txs: [KrystalHistoryTransaction]) -> Bool {
    guard let unwrapped = self.wallet else {
      return false
    }
    var newTx: [KrystalHistoryTransaction] = []
    txs.forEach { item in
      if !self.krystalHistoryTransaction.contains(item) {
        newTx.append(item)
      }
    }
    guard !newTx.isEmpty else {
      return false
    }
    self.krystalHistoryTransaction = newTx + self.krystalHistoryTransaction
    if self.isSavedKrystalHistory() { //Has data of first block
      Storage.store(self.krystalHistoryTransaction, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName)
    }
    return true
  }
  
  fileprivate func checkRemoveInternalHistoryTransaction(_ hash: String) {
    let pendingHash = self.internalHistoryTransactions.map { $0.hash.lowercased() }
    if pendingHash.contains(hash.lowercased()) {
      let transaction = self.getInternalHistoryTransactionWithHash(hash.lowercased())
      KNNotificationUtil.postNotification(
        for: kTransactionDidUpdateNotificationKey,
        object: transaction,
        userInfo: nil
      )
      
      self.removeInternalHistoryTransactionWithHash(hash.lowercased())
    }
  }
  
  func getKrystalHistoryTransactionStartBlock() -> String {
    if let blockNo = self.krystalHistoryTransaction.first?.blockNumber {
      return "\(blockNo)"
    } else {
      return ""
    }
  }
  
  func getInternalHistoryTransaction() -> [InternalHistoryTransaction] {
    return self.internalHistoryTransactions.filter { transaction in
      transaction.state == .pending
    }
  }
  
  func getHandledInternalHistoryTransactionForUnsupportedApi() -> [InternalHistoryTransaction] {
    return self.internalHistoryTransactions.filter { transaction in
      transaction.state != .pending
    }
  }
  
  func appendInternalHistoryTransaction(_ tx: InternalHistoryTransaction) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.internalHistoryTransactions.append(tx)
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: tx,
      userInfo: nil
    )
    Storage.store(self.internalHistoryTransactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName)
  }
  
  func isContainInsternalSendTransaction() -> Bool {
    let result = self.internalHistoryTransactions.first { (item) -> Bool in
      return item.type == .transferETH || item.type == .transferToken || item.type == .swap || item.type == .earn
    }
    return result != nil
  }

  func getInternalHistoryTransactionWithHash(_ hash: String) -> InternalHistoryTransaction? {
    return self.internalHistoryTransactions.first { (item) -> Bool in
      return item.hash.lowercased() == hash
    }
  }
  
  @discardableResult
  func removeInternalHistoryTransactionWithHash(_ hash: String) -> Bool {
    guard let unwrapped = self.wallet else {
      return false
    }
    guard let index = self.internalHistoryTransactions.firstIndex(where: { (item) -> Bool in
      return item.hash.lowercased() == hash.lowercased()
    }) else {
      return false
    }
    self.internalHistoryTransactions.remove(at: index)
    Storage.store(self.internalHistoryTransactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName)
    return true
  }
  
  func updateInternalHistoryTransactionForUnsupportedChain(_ transaction: InternalHistoryTransaction) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.internalHistoryTransactions.forEach { internalTransaction in
      if internalTransaction.hash == transaction.hash {
        internalTransaction.state = transaction.state
      }
    }
    Storage.store(self.internalHistoryTransactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName)
  }
  
  func getInternalHistoryTokenSymbols() -> [String] {
    var symbols: [String] = []
    self.internalHistoryTransactions.forEach { transaction in
      if let fromSymbol = transaction.fromSymbol, !symbols.contains(fromSymbol) {
        symbols.append(fromSymbol)
      }
      if let toSymbol = transaction.toSymbol, !symbols.contains(toSymbol) {
        symbols.append(toSymbol)
      }
    }
    return symbols
  }
  
  func getEtherscanToken() -> [Token] {
    var tokenSet = Set<Token>()

    self.krystalHistoryTransaction.forEach { transaction in
      if let token = transaction.extraData?.receiveToken, !token.symbol.isEmpty {
        tokenSet.insert(token)
      }
      if let token = transaction.extraData?.sendToken, !token.symbol.isEmpty {
        tokenSet.insert(token)
      }
      if let token = transaction.extraData?.token, !token.symbol.isEmpty {
        tokenSet.insert(token)
      }
    }

    return Array(tokenSet).sorted { (left, right) -> Bool in
      return left.symbol > right.symbol
    }
  }
}
