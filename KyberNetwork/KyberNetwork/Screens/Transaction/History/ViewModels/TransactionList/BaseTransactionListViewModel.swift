//
//  BaseTransactionListViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation

class BaseTransactionListViewModel {
  var wallet: KNWalletObject
  
  var isTransactionActionEnabled: Bool = false
  var canRefresh: Bool = false
  var canLoadMore: Bool = false
  var isLoading: Bool = true
  
  var transactions: [TransactionHistoryItem] = []
  var headers: [String] = []
  var groupedTransactions: Observable<[String: [TransactionHistoryItem]]> = .init([:])
  
  init(wallet: KNWalletObject) {
    self.wallet = wallet
  }
  
  func reload() {
    
  }
  
  func load() {
    
  }
  
  func applyFilter(filter: KNTransactionFilter) {
    
  }
  
  func updateWallet(wallet: KNWalletObject) {
    self.wallet = wallet
  }
}

extension BaseTransactionListViewModel {
  
  var isTransactionListEmpty: Bool {
    return headers.isEmpty
  }
  
  var numberOfSections: Int {
    return headers.count
  }
  
  func numberOfItems(inSection section: Int) -> Int {
    return groupedTransactions.value[headers[section]]?.count ?? 0
  }
  
  func headerTitle(forSection section: Int) -> String {
    return headers[section]
  }
  
  func item(forIndex index: Int, inSection section: Int) -> TransactionHistoryItem? {
    return groupedTransactions.value[headers[section]]?[index]
  }
  
}
