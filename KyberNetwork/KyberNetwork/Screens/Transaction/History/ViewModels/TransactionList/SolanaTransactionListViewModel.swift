//
//  SolanaTransactionListViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation
import KrystalWallets

class SolanaTransactionListViewModel: BaseTransactionListViewModel {
  let getSolanaTransactionsUseCase: GetSolanaTransactionsUseCase
  let dateFormatter = DateFormatterUtil.shared.limitOrderFormatter
  var lastHash: String?
  var timer: Timer?
  
  init(address: KAddress, getSolanaTransactionsUseCase: GetSolanaTransactionsUseCase) {
    self.getSolanaTransactionsUseCase = getSolanaTransactionsUseCase
    super.init(address: address)
    self.canLoadMore = true
    self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(scheduledFetchTransactions), userInfo: nil, repeats: true)
    RunLoop.current.add(timer!, forMode: .common)
  }
  
  deinit {
    self.timer?.invalidate()
    self.timer = nil
  }
  
  override func loadCacheData() {
    self.transactions = getSolanaTransactionsUseCase.loadCachedTransactions()
    self.onTransactionsListChanged()
  }
  
  override func reload() {
    self.isLoading = true
    self.getSolanaTransactionsUseCase.load(lastHash: nil) { [weak self] transactions, hasMore in
      guard let self = self else { return }
      self.canLoadMore = hasMore
      self.isLoading = false
      self.transactions = transactions.isEmpty ? self.getSolanaTransactionsUseCase.loadCachedTransactions() : transactions
      self.lastHash = self.transactions.last?.txHash
      self.onTransactionsListChanged()
    }
  }
  
  override func load() {
    self.isLoading = true
    self.getSolanaTransactionsUseCase.load(lastHash: lastHash) { [weak self] transactions, hasMore in
      self?.canLoadMore = hasMore
      self?.isLoading = false
      self?.appendTransactions(newTransactions: transactions)
      self?.lastHash = transactions.last?.txHash
    }
  }
  
  @objc func scheduledFetchTransactions() {
    self.getSolanaTransactionsUseCase.load(lastHash: nil) { [weak self] newTransactions, _ in
      guard let self = self else { return }
      self.transactions.removeAll { tx in
        newTransactions.contains { $0.txHash == tx.txHash }
      }
      self.transactions = newTransactions + self.transactions
      self.onTransactionsListChanged()
    }
  }
  
  private func appendTransactions(newTransactions: [SolanaTransaction]) {
    self.transactions += newTransactions
    self.onTransactionsListChanged()
  }
  
  func onTransactionsListChanged() {
    self.getSolanaTransactionsUseCase.saveTransactions(
      transactions: transactions as! [SolanaTransaction]
    )
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
  
  override func updateWallet(address: KAddress) {
    self.address = address
    self.getSolanaTransactionsUseCase.address = address.addressString
    self.reload()
  }
  
}
