//
//  EtherscanTransactionStorage.swift
//  KyberNetwork
//
//  Created by Com1 on 11/02/2022.
//

import Foundation

class EtherscanTransactionStorage: NSObject {
  static let shared = EtherscanTransactionStorage()
  private var wallet: Wallet?
  private var tokenTransactions: [EtherscanTokenTransaction] = []
  private var internalTransaction: [EtherscanInternalTransaction] = []
  private var nftTransaction: [NFTTransaction] = []
  private var transactions: [EtherscanTransaction] = []
  private var historyTransactionModel: [HistoryTransaction] = []

  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet
    self.tokenTransactions = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName, as: [EtherscanTokenTransaction].self) ?? []
    self.internalTransaction = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName, as: [EtherscanInternalTransaction].self) ?? []
    self.nftTransaction = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.etherscanNFTTransactionsStoreFileName, as: [NFTTransaction].self) ?? []
    self.transactions = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName, as: [EtherscanTransaction].self) ?? []
    self.historyTransactionModel = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.historyTransactionsStoreFileName, as: [HistoryTransaction].self) ?? []
  }

  func setTokenTransactions(_ transactions: [EtherscanTokenTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.tokenTransactions = transactions
    Storage.store(transactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName)
  }

  func setInternalTransactions(_ transactions: [EtherscanInternalTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.internalTransaction = transactions
    Storage.store(transactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName)
  }
  
  func setNFTTransaction(_ transactions: [NFTTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.nftTransaction = transactions
    Storage.store(transactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanNFTTransactionsStoreFileName)
  }

  func setTransactions(_ transactions: [EtherscanTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.transactions = transactions
    Storage.store(transactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName)
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

  func appendTokenTransactions(_ transactions: [EtherscanTokenTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    var newTx: [EtherscanTokenTransaction] = []
    transactions.forEach { (item) in
      if !self.tokenTransactions.contains(item) {
        newTx.append(item)
      }
//      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    
    let result = newTx + self.tokenTransactions
    Storage.store(result, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName)
    self.tokenTransactions = result
  }

  func appendInternalTransactions(_ transactions: [EtherscanInternalTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    var newTx: [EtherscanInternalTransaction] = []
    transactions.forEach { (item) in
      if !self.internalTransaction.contains(item) {
        newTx.append(item)
      }
//      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.internalTransaction
    Storage.store(result, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName)
    self.internalTransaction = result
  }
  
  func appendNFTTransactions(_ transactions: [NFTTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    var newTx: [NFTTransaction] = []
    transactions.forEach { (item) in
      if !self.nftTransaction.contains(item) {
        newTx.append(item)
      }
//      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.nftTransaction
    Storage.store(result, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanNFTTransactionsStoreFileName)
    self.nftTransaction = result
  }

  func appendTransactions(_ transactions: [EtherscanTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    var newTx: [EtherscanTransaction] = []
    transactions.forEach { (item) in
      if !self.transactions.contains(item) {
        newTx.append(item)
      }
//      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.transactions
    Storage.store(result, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName)
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
    guard let unwrapped = self.wallet else {
      return
    }
    
    let storedHashs = self.historyTransactionModel.map { $0.hash }
    
    var historyModel: [HistoryTransaction] = []
    self.getTransaction().forEach { (transaction) in
      var type = HistoryModelType.typeFromInput(transaction.input)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      let relatedNFTTx = self.getNFTTransactionsWithHash(transaction.hash)
      if type == .transferETH && transaction.from == transaction.to {
        type = .selfTransfer
      } else if transaction.from.lowercased() != unwrapped.address.description.lowercased() && transaction.to.lowercased() == unwrapped.address.description.lowercased() {
        type = .receiveETH
      }
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: [transaction], internalTransactions: relatedInternalTx, tokenTransactions: relatedTokenTx, nftTransaction: relatedNFTTx, wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    let etherscanTxHash = self.getTransaction().map { $0.hash }
    let internalTx = self.getInternalTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    internalTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      let model = HistoryTransaction(type: .receiveETH, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: [transaction], tokenTransactions: relatedTokenTx, nftTransaction: [], wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    let tokenTx = self.getTokenTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    tokenTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let type: HistoryModelType = transaction.from.lowercased() == unwrapped.address.description.lowercased() ? .transferToken : .receiveToken
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: relatedInternalTx, tokenTransactions: [transaction], nftTransaction: [], wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    
    let nftTx = self.getNFTTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    nftTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let type: HistoryModelType = transaction.from.lowercased() == unwrapped.address.description.lowercased() ? .transferNFT : .receiveNFT
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: [], tokenTransactions: [], nftTransaction: [transaction], wallet: unwrapped.address.description.lowercased())
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
    Storage.store(self.historyTransactionModel, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.historyTransactionsStoreFileName)
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
}
