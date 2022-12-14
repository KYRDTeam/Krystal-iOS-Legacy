//
//  EtherscanTransactionStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/9/21.
//

import Foundation
import KrystalWallets
import AppState
import TransactionModule

class EtherscanTransactionStorage {
  static let shared = EtherscanTransactionStorage()
//  private var address: KAddress?
  var address: KAddress {
    return AppState.shared.currentAddress
  }
  private var tokenTransactions: [EtherscanTokenTransaction] = []
  private var internalTransaction: [EtherscanInternalTransaction] = []
  private var nftTransaction: [NFTTransaction] = []
  private var transactions: [EtherscanTransaction] = []
  private var historyTransactionModel: [HistoryTransaction] = []
  private var internalHistoryTransactions: [InternalHistoryTransaction] = []
  private var krystalHistoryTransaction: [KrystalHistoryTransaction] = []

  func updateCurrentHistoryCache() {
    self.tokenTransactions = Storage.retrieve(address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName, as: [EtherscanTokenTransaction].self) ?? []
    self.internalTransaction = Storage.retrieve(address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName, as: [EtherscanInternalTransaction].self) ?? []
    self.nftTransaction = Storage.retrieve(address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanNFTTransactionsStoreFileName, as: [NFTTransaction].self) ?? []
    self.transactions = Storage.retrieve(address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName, as: [EtherscanTransaction].self) ?? []
    self.historyTransactionModel = Storage.retrieve(address.addressString + KNEnvironment.default.envPrefix + Constants.historyTransactionsStoreFileName, as: [HistoryTransaction].self) ?? []
    self.krystalHistoryTransaction = Storage.retrieve(address.addressString + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName, as: [KrystalHistoryTransaction].self) ?? []
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      // Incase current chain didn't support get history api
      self.internalHistoryTransactions = Storage.retrieve(address.addressString + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName, as: [InternalHistoryTransaction].self) ?? []
    } else {
      self.internalHistoryTransactions = []
    }
  }
  
  func isSavedKrystalHistory() -> Bool {
    return Storage.isFileExistAtPath(address.addressString + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName)
  }
  
  func setTokenTransactions(_ transactions: [EtherscanTokenTransaction]) {
    self.tokenTransactions = transactions
    Storage.store(transactions, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName)
  }

  func setInternalTransactions(_ transactions: [EtherscanInternalTransaction]) {
    self.internalTransaction = transactions
    Storage.store(transactions, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName)
  }
  
  func setNFTTransaction(_ transactions: [NFTTransaction]) {
    self.nftTransaction = transactions
    Storage.store(transactions, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanNFTTransactionsStoreFileName)
  }

  func setTransactions(_ transactions: [EtherscanTransaction]) {
    self.transactions = transactions
    Storage.store(transactions, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName)
  }

  func getTokenTransaction() -> [EtherscanTokenTransaction] {
    return self.tokenTransactions
  }

  func getInternalTransaction() -> [EtherscanInternalTransaction] {
    return self.internalTransaction
  }
  
  func getNFTTransaction() -> [NFTTransaction] {
    return self.nftTransaction
  }

  func getTransaction() -> [EtherscanTransaction] {
    return self.transactions
  }
  
  func getKrystalTransaction() -> [KrystalHistoryTransaction] {
    return self.krystalHistoryTransaction
  }

  func setKrystalTransaction(_ txs: [KrystalHistoryTransaction], isSave: Bool = true) {
    self.krystalHistoryTransaction = txs
    if isSave {
      Storage.store(self.krystalHistoryTransaction, as: address.addressString + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName)
    }
  }

  func appendKrystalTransaction(_ txs: [KrystalHistoryTransaction]) -> Bool {
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
      Storage.store(self.krystalHistoryTransaction, as: address.addressString + KNEnvironment.default.envPrefix + Constants.historyKrystalTransactionsStoreFileName)
    }
    return true
  }

  func appendTokenTransactions(_ transactions: [EtherscanTokenTransaction]) {
    var newTx: [EtherscanTokenTransaction] = []
    transactions.forEach { (item) in
      if !self.tokenTransactions.contains(item) {
        newTx.append(item)
      }
      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    
    let result = newTx + self.tokenTransactions
    Storage.store(result, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName)
    self.tokenTransactions = result
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
        if let tx = transaction {
            TransactionManager.onTransactionStatusUpdated(hash: hash, status: tx.state)
        }
      self.removeInternalHistoryTransactionWithHash(hash.lowercased())
    }
  }

  func appendInternalTransactions(_ transactions: [EtherscanInternalTransaction]) {
    var newTx: [EtherscanInternalTransaction] = []
    transactions.forEach { (item) in
      if !self.internalTransaction.contains(item) {
        newTx.append(item)
      }
      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.internalTransaction
    Storage.store(result, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName)
    self.internalTransaction = result
  }
  
  func appendNFTTransactions(_ transactions: [NFTTransaction]) {
    var newTx: [NFTTransaction] = []
    transactions.forEach { (item) in
      if !self.nftTransaction.contains(item) {
        newTx.append(item)
      }
      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.nftTransaction
    Storage.store(result, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanNFTTransactionsStoreFileName)
    self.nftTransaction = result
  }

  func appendTransactions(_ transactions: [EtherscanTransaction]) {
    var newTx: [EtherscanTransaction] = []
    transactions.forEach { (item) in
      if !self.transactions.contains(item) {
        newTx.append(item)
      }
      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.transactions
    Storage.store(result, as: address.addressString + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName)
    self.transactions = result
  }

  func getCurrentTokenTransactionStartBlock() -> String {
    return self.tokenTransactions.first?.blockNumber ?? ""
  }
  
  func getCurrentInternalTransactionStartBlock() -> String {
    return self.internalTransaction.first?.blockNumber ?? ""
  }
  
  func getCurrentNFTTransactionStartBlock() -> String {
    return self.nftTransaction.first?.blockNumber ?? ""
  }
  
  func getCurrentTransactionStartBlock() -> String {
    return self.transactions.first?.blockNumber ?? ""
  }
  
  func getKrystalHistoryTransactionStartBlock() -> String {
    if let blockNo = self.krystalHistoryTransaction.first?.blockNumber {
      return "\(blockNo)"
    } else {
      return ""
    }
  }

  func getInternalTransactionsWithHash(_ hash: String) -> [EtherscanInternalTransaction] {
    return self.internalTransaction.filter { (item) -> Bool in
      return item.hash == hash
    }
  }
  
  func getNFTTransactionsWithHash(_ hash: String) -> [NFTTransaction] {
    return self.nftTransaction.filter { (item) -> Bool in
      return item.hash.lowercased() == hash.lowercased()
    }
  }

  func getTokenTransactionWithHash(_ hash: String) -> [EtherscanTokenTransaction] {
    return self.tokenTransactions.filter { (item) -> Bool in
      return item.hash == hash
    }
  }

  func getTransactionWithHash(_ hash: String) -> [EtherscanTransaction] {
    return self.transactions.filter { (item) -> Bool in
      return item.hash == hash
    }
  }

  func generateKrytalTransactionModel(completion: @escaping () -> Void) {
    let storedHashs = self.historyTransactionModel.map { $0.hash }
    
    var historyModel: [HistoryTransaction] = []
    self.getTransaction().forEach { (transaction) in
      var type = HistoryModelType.typeFromInput(transaction.input)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      let relatedNFTTx = self.getNFTTransactionsWithHash(transaction.hash)
      if type == .transferETH && transaction.from == transaction.to {
        type = .selfTransfer
      } else if transaction.from.lowercased() != address.addressString && transaction.to.lowercased() == address.addressString {
        type = .receiveETH
      }
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: [transaction], internalTransactions: relatedInternalTx, tokenTransactions: relatedTokenTx, nftTransaction: relatedNFTTx, wallet: address.addressString)
      historyModel.append(model)
    }
    let etherscanTxHash = self.getTransaction().map { $0.hash }
    let internalTx = self.getInternalTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    internalTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      let model = HistoryTransaction(type: .receiveETH, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: [transaction], tokenTransactions: relatedTokenTx, nftTransaction: [], wallet: address.addressString)
      historyModel.append(model)
    }
    let tokenTx = self.getTokenTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    tokenTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let type: HistoryModelType = transaction.from.lowercased() == address.addressString ? .transferToken : .receiveToken
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: relatedInternalTx, tokenTransactions: [transaction], nftTransaction: [], wallet: address.addressString)
      historyModel.append(model)
    }
    
    let nftTx = self.getNFTTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    nftTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let type: HistoryModelType = transaction.from.lowercased() == address.addressString ? .transferNFT : .receiveNFT
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: [], tokenTransactions: [], nftTransaction: [transaction], wallet: address.addressString)
      historyModel.append(model)
    }
    
    
    historyModel.sort { (left, right) -> Bool in
      return left.timestamp > right.timestamp
    }
    
    var newestTxs: [HistoryTransaction] = []
    historyModel.forEach { (txItem) in
      if !storedHashs.contains(txItem.hash) {
        newestTxs.append(txItem)
      }
    }
    
    self.historyTransactionModel = historyModel
    Storage.store(self.historyTransactionModel, as: address.addressString + KNEnvironment.default.envPrefix + Constants.historyTransactionsStoreFileName)
    completion()
    DispatchQueue.main.async {
      KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
      newestTxs.forEach { (item) in
        if item.date.addingTimeInterval(10800) > Date() {
          if item.type == .receiveETH || item.type == .receiveToken || item.type == .earn {
            KNNotificationUtil.postNotification(for: kNewReceivedTransactionKey, object: item)
          }
        }
      }
    }
  }

  func getHistoryTransactionModel() -> [HistoryTransaction] {
    return self.historyTransactionModel
  }
    
    func getInternalHistoryTransaction(chain: ChainType = AppState.shared.currentChain) -> [InternalHistoryTransaction] {
        return self.internalHistoryTransactions.filter { transaction in
            transaction.state == .pending && chain == transaction.chain
        }
    }
    
  func getHandledInternalHistoryTransactionForUnsupportedApi() -> [InternalHistoryTransaction] {
    return self.internalHistoryTransactions.filter { transaction in
      transaction.state != .pending
    }
  }

  func appendInternalHistoryTransaction(_ tx: InternalHistoryTransaction) {
    self.internalHistoryTransactions.append(tx)
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: tx,
      userInfo: nil
    )
      TransactionManager.onTransactionStatusUpdated(hash: tx.txHash, status: tx.state)
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      Storage.store(self.internalHistoryTransactions, as: address.addressString + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName)
    }
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
    guard let index = self.internalHistoryTransactions.firstIndex(where: { (item) -> Bool in
      return item.hash.lowercased() == hash.lowercased()
    }) else {
      return false
    }
    self.internalHistoryTransactions.remove(at: index)
    
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      Storage.store(self.internalHistoryTransactions, as: address.addressString + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName)
    }
    return true
  }
  
  func updateInternalHistoryTransactionForUnsupportedChain(_ transaction: InternalHistoryTransaction) {
    self.internalHistoryTransactions.forEach { internalTransaction in
      if internalTransaction.hash == transaction.hash {
        internalTransaction.state = transaction.state
      }
    }
    Storage.store(self.internalHistoryTransactions, as: address.addressString + KNEnvironment.default.envPrefix + Constants.unsupportedChainHistoryTransactionsFileName)
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
