//
//  EtherscanTransactionStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/9/21.
//

import Foundation

class EtherscanTransactionStorage {
  static let shared = EtherscanTransactionStorage()
  private var wallet: Wallet?
  private var tokenTransactions: [EtherscanTokenTransaction] = []
  private var internalTransaction: [EtherscanInternalTransaction] = []
  private var transactions: [EtherscanTransaction] = []
  private var historyTransactionModel: [HistoryTransaction] = []

  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet
    self.tokenTransactions = Storage.retrieve(wallet.address.description + Constants.etherscanTokenTransactionsStoreFileName, as: [EtherscanTokenTransaction].self) ?? []
    self.internalTransaction = Storage.retrieve(wallet.address.description + Constants.etherscanInternalTransactionsStoreFileName, as: [EtherscanInternalTransaction].self) ?? []
    self.transactions = Storage.retrieve(wallet.address.description + Constants.etherscanTransactionsStoreFileName, as: [EtherscanTransaction].self) ?? []
    self.generateKrytalTransactionModel()
  }
  
  func setTokenTransactions(_ transactions: [EtherscanTokenTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.tokenTransactions = transactions
    Storage.store(transactions, as: unwrapped.address.description + Constants.etherscanTokenTransactionsStoreFileName)
  }

  func setInternalTransactions(_ transactions: [EtherscanInternalTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.internalTransaction = transactions
    Storage.store(transactions, as: unwrapped.address.description + Constants.etherscanInternalTransactionsStoreFileName)
  }

  func setTransactions(_ transactions: [EtherscanTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.transactions = transactions
    Storage.store(transactions, as: unwrapped.address.description + Constants.etherscanTransactionsStoreFileName)
  }

  func getTokenTransaction() -> [EtherscanTokenTransaction] {
    return self.tokenTransactions
  }
  
  func getInternalTransaction() -> [EtherscanInternalTransaction] {
    return self.internalTransaction
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
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.tokenTransactions
    Storage.store(result, as: unwrapped.address.description + Constants.etherscanTokenTransactionsStoreFileName)
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
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.internalTransaction
    Storage.store(result, as: unwrapped.address.description + Constants.etherscanInternalTransactionsStoreFileName)
    self.internalTransaction = result
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
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.transactions
    Storage.store(result, as: unwrapped.address.description + Constants.etherscanTransactionsStoreFileName)
    self.transactions = result
  }
  
  func getCurrentTokenTransactionStartBlock() -> String {
    return self.tokenTransactions.first?.blockNumber ?? ""
  }
  
  func getCurrentInternalTransactionStartBlock() -> String {
    return self.internalTransaction.first?.blockNumber ?? ""
  }
  
  func getCurrentTransactionStartBlock() -> String {
    return self.transactions.first?.blockNumber ?? ""
  }
  
  func getInternalTransactionsWithHash(_ hash: String) -> [EtherscanInternalTransaction] {
    return self.internalTransaction.filter { (item) -> Bool in
      return item.hash == hash
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

  func generateKrytalTransactionModel() {
    guard let unwrapped = self.wallet else {
      return
    }
    var historyModel: [HistoryTransaction] = []
    self.getTransaction().forEach { (transaction) in
      var type = HistoryModelType.typeFromInput(transaction.input)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      if type == .transferETH && transaction.from == transaction.to {
        type = .selfTransfer
      }
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: [transaction], internalTransactions: relatedInternalTx, tokenTransactions: relatedTokenTx, wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    let etherscanTxHash = self.getTransaction().map { $0.hash }
    let internalTx = self.getInternalTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    internalTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      let model = HistoryTransaction(type: .receiveETH, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: [transaction], tokenTransactions: relatedTokenTx, wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    let tokenTx = self.getTokenTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    tokenTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let type: HistoryModelType = transaction.from.lowercased() == unwrapped.address.description.lowercased() ? .transferToken : .receiveToken
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: relatedInternalTx, tokenTransactions: [transaction], wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    historyModel.sort { (left, right) -> Bool in
      return left.timestamp > right.timestamp
    }
    self.historyTransactionModel = historyModel
  }

  func getHistoryTransactionModel() -> [HistoryTransaction] {
    return self.historyTransactionModel
  }
}
