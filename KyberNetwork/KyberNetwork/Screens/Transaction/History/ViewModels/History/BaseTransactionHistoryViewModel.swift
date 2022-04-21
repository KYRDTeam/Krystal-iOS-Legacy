//
//  BaseTransactionHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation

class BaseTransactionHistoryViewModel: TransactionHistoryViewModelProtocol {
  private lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  var canRefresh: Bool {
    return true
  }
  var isTransactionActionEnabled: Bool {
    return false
  }
  var allTokens: [String] = []
  var currentWallet: KNWalletObject
  var filter: KNTransactionFilter!
  var displayTransactions: [String: [TransactionHistoryItem]] = [:]
  var displayHeaders: [String] = []
  
  var allHeaders: [String] = []
  var allTransactions: [String: [TransactionHistoryItem]] = [:]
  
  init(currentWallet: KNWalletObject) {
    self.currentWallet = currentWallet
  }
  
  func fetchAllTransactions() -> [TransactionHistoryItem] {
    fatalError("Must override this function")
  }
  
  func reloadData() {
    let transactions = fetchAllTransactions()
    self.allHeaders = transactions
      .map { $0.txDate.startDate() }
      .unique
      .sorted(by: >)
      .map { dateFormatter.string(from: $0) }
      
    self.allTransactions = Dictionary(grouping: transactions) { dateFormatter.string(from: $0.txDate) }

    self.filterTransactions()
  }
  
  private func filterTransactions() {
    let from = filter.from ?? Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    let to = filter.to ?? Date().addingTimeInterval(24.0 * 60.0 * 60.0)
    
    var date = Date()
    let headers = allHeaders.filter {
      let date = self.dateFormatter.date(from: $0) ?? Date()
      return date >= from.startDate() && date < to.endDate()
    }
    date = Date()
    self.displayTransactions = {
      var dictionary = [String: [TransactionHistoryItem]]()
      headers.forEach { header in
        dictionary[header] = allTransactions[header]?
          .filter { $0.match(filter: filter, allTokens: allTokens) }
          .sorted { $0.txDate > $1.txDate }
      }
      return dictionary
    }()
    
    self.displayHeaders = headers.filter { displayTransactions[$0]?.isEmpty == false }
    
  }
  
  func applyFilter(filter: KNTransactionFilter) {
    self.filter = filter
    self.filterTransactions()
  }
  
  func updateWallet(wallet: KNWalletObject) {
    self.currentWallet = wallet
    self.reloadData()
  }
  
}
