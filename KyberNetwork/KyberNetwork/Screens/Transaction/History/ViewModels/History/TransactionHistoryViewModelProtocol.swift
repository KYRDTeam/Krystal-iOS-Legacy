//
//  KNHistoryViewModelProtocol.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation

protocol TransactionHistoryViewModelProtocol {
  var canRefresh: Bool { get }
  var isTransactionActionEnabled: Bool { get }
  var displayHeaders: [String] { get }
  var displayTransactions: [String: [TransactionHistoryItem]] { get }
  
  func applyFilter(filter: KNTransactionFilter)
  func updateWallet(wallet: KNWalletObject)
  func reloadData()
}

extension TransactionHistoryViewModelProtocol {
  
  var isTransactionListEmpty: Bool {
    return displayHeaders.isEmpty
  }
  
  var numberOfSections: Int {
    return displayHeaders.count
  }
  
  func numberOfItems(inSection section: Int) -> Int {
    return displayTransactions[displayHeaders[section]]?.count ?? 0
  }
  
  func headerTitle(forSection section: Int) -> String {
    return displayHeaders[section]
  }
  
  func item(forIndex index: Int, inSection section: Int) -> TransactionHistoryItem? {
    return displayTransactions[displayHeaders[section]]?[index]
  }
  
}
