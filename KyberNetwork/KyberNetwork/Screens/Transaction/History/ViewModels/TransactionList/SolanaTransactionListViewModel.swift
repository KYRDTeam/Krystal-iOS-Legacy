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
  
  init(wallet: KNWalletObject, getSolanaTransactionsUseCase: GetSolanaTransactionsUseCase) {
    self.getSolanaTransactionsUseCase = getSolanaTransactionsUseCase
    super.init(wallet: wallet)
    self.canLoadMore = true
    self.canRefresh = true
  }
  
  override func reload(completion: @escaping () -> ()) {
    self.reset()
    self.load(completion: completion)
  }
  
  override func load(completion: @escaping () -> ()) {
    self.isLoading = true
    self.getSolanaTransactionsUseCase.load { [weak self] transactions, hasMore in
      self?.canLoadMore = hasMore
      self?.isLoading = false
      self?.appendTransactions(newTransactions: transactions)
      completion()
    }
  }
  
  private func reset() {
    self.getSolanaTransactionsUseCase.lastHash = nil
    self.transactions = []
    self.headers = []
    self.groupedTransactions = [:]
  }
  
  private func appendTransactions(newTransactions: [SolanaTransaction]) {
    self.transactions += newTransactions
    newTransactions.forEach { tx in
      let formattedDate = dateFormatter.string(from: tx.txDate)
      if !headers.contains(formattedDate) {
        headers.append(formattedDate)
      }
      let txs = groupedTransactions[formattedDate] ?? []
      groupedTransactions[formattedDate] = txs + [tx]
    }
  }
  
}

extension SolanaTransaction: TransactionHistoryItem {
  
  var txDate: Date {
    return Date(timeIntervalSince1970: Double(blockTime))
  }
  
  func toViewModel() -> TransactionHistoryItemViewModelProtocol {
    return KrystalSolanaTransactionItemViewModel(transaction: self)
  }
  
}
