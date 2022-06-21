//
//  BasePendingTransactionListViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import Foundation
import KrystalWallets

class BasePendingTransactionListViewModel {
  let dateFormatter = DateFormatterUtil.shared.limitOrderFormatter
  var address: KAddress
  var transactions: [InternalHistoryTransaction] = []
  var headers: [String] = []
  var groupedTransactions: Observable<[String: [InternalHistoryTransaction]]> = .init([:])
  var isTransactionActionEnabled: Bool = false
  
  init(address: KAddress) {
    self.address = address
    self.observeTxNotifications()
  }
  
  func reload() {
    self.transactions = EtherscanTransactionStorage.shared.getInternalHistoryTransaction()
    self.recalculate()
  }
  
  func updateAddress(address: KAddress) {
    self.address = address
    self.reload()
  }
  
  func recalculate() {
    var headers: [String] = []
    var groupedTransactions: [String: [InternalHistoryTransaction]] = [:]
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
  
  private func observeTxNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.transactionStateDidUpdate(_:)),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
  }
  
  @objc func transactionStateDidUpdate(_ sender: Notification) {
    self.reload()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
  }
  
}

extension BasePendingTransactionListViewModel {
  
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
  
  func item(forIndex index: Int, inSection section: Int) -> InternalHistoryTransaction? {
    return groupedTransactions.value[headers[section]]?[index]
  }
  
}
