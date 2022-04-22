//
//  KNTransactionListViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

class KNTransactionListViewModel {
  let fetchTransactionsUseCase: FetchTransactionsUseCase
  let fetchTokensUseCase: FetchTokensUseCase
  var wallet: KNWalletObject
  var filter: KNTransactionFilter!
  
  var isTransactionActionEnabled: Bool
  var canRefresh: Bool
  
  var allTokens: [String]
  var allHeaders: [String] = []
  var allTransactions: [String: [TransactionHistoryItem]] = [:]
  var displayTransactions: [String: [TransactionHistoryItem]] = [:]
  var displayHeaders: [String] = []
  
  private lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  
  init(fetchTransactionsUseCase: FetchTransactionsUseCase,
       fetchTokensUseCase: FetchTokensUseCase,
       wallet: KNWalletObject,
       isTransactionActionEnabled: Bool,
       canRefresh: Bool) {
    self.wallet = wallet
    self.isTransactionActionEnabled = isTransactionActionEnabled
    self.canRefresh = canRefresh
    self.fetchTransactionsUseCase = fetchTransactionsUseCase
    self.fetchTokensUseCase = fetchTokensUseCase
    self.allTokens = fetchTokensUseCase.execute()
    self.filter = KNTransactionFilter(
      from: nil,
      to: nil,
      isSend: true,
      isReceive: true,
      isSwap: true,
      isApprove: true,
      isWithdraw: true,
      isTrade: true,
      isContractInteraction: true,
      isClaimReward: true,
      tokens: self.allTokens
    )
  }
  
  func reloadData() {
    let transactions = fetchTransactionsUseCase.execute()
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
    
    let headers = allHeaders.filter {
      let date = self.dateFormatter.date(from: $0) ?? Date()
      return date >= from.startDate() && date < to.endDate()
    }
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
    self.wallet = wallet
    self.reloadData()
  }
}

extension KNTransactionListViewModel {
  
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

