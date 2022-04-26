//
//  SolanaTransactionListViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation

class SolanaTransactionListViewModel: BaseTransactionListViewModel {
  
  let getSolanaTransactionsUseCase: GetSolanaTransactionsUseCase
  let dateFormatter = DateFormatterUtil.shared.limitOrderFormatter
  var lastHash: String?
  var timer: Timer?
  
  init(wallet: KNWalletObject, getSolanaTransactionsUseCase: GetSolanaTransactionsUseCase) {
    self.getSolanaTransactionsUseCase = getSolanaTransactionsUseCase
    super.init(wallet: wallet)
    self.canLoadMore = true
    self.canRefresh = true
    self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(scheduledFetchTransactions), userInfo: nil, repeats: true)
    RunLoop.current.add(timer!, forMode: .common)
  }
  
  deinit {
    self.timer?.invalidate()
    self.timer = nil
  }
  
  override func reload() {
    self.lastHash = nil
    self.isLoading = true
    self.getSolanaTransactionsUseCase.load(lastHash: lastHash) { [weak self] transactions, hasMore in
      self?.transactions = []
      self?.headers = []
      self?.groupedTransactions.value = [:]
      self?.canLoadMore = hasMore
      self?.isLoading = false
      self?.lastHash = transactions.last?.txHash
      self?.appendTransactions(newTransactions: transactions)
    }
  }
  
  override func load() {
    self.isLoading = true
    self.getSolanaTransactionsUseCase.load(lastHash: lastHash) { [weak self] transactions, hasMore in
      self?.canLoadMore = hasMore
      self?.isLoading = false
      self?.lastHash = transactions.last?.txHash
      self?.appendTransactions(newTransactions: transactions)
    }
  }
  
  @objc func scheduledFetchTransactions() {
    self.getSolanaTransactionsUseCase.load(lastHash: nil) { [weak self] newTransactions, _ in
      guard let self = self else { return }
      self.transactions.removeAll { tx in
        newTransactions.contains { $0.txHash == tx.txHash }
      }
      self.transactions = newTransactions + self.transactions
      self.recalculate()
    }
  }
  
  private func appendTransactions(newTransactions: [SolanaTransaction]) {
    self.transactions += newTransactions
    self.recalculate()
  }
  
  func recalculate() {
    var headers: [String] = []
    var groupedTransactions: [String: [TransactionHistoryItem]] = [:]
    transactions.forEach { tx in
      let formattedDate = dateFormatter.string(from: tx.txDate)
      if !headers.contains(formattedDate) {
        headers.append(formattedDate)
      }
      let txs = groupedTransactions[formattedDate] ?? []
      groupedTransactions[formattedDate] = txs + [tx]
    }
    self.headers = headers
    self.groupedTransactions.value = groupedTransactions
  }
  
  override func updateWallet(wallet: KNWalletObject) {
    self.wallet = wallet
    self.getSolanaTransactionsUseCase.address = wallet.address
  }
  
}
