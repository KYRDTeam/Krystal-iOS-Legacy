//
//  EarnListViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 19/10/2022.
//

import UIKit
import Dependencies
import AppState


class EarnOverViewModel {
  var hasPendingTransaction: Observable<Bool> = .init(false)
  var currentChain: Observable<ChainType> = .init(AppState.shared.currentChain)
  init() {
//    self.observeNotifications()
  }
  
  deinit {
//    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidChangeAddress, object: nil)
  }

  func checkPendingTx() {
//    let pendingTransaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().first { transaction in
//      transaction.state == .pending
//    }
//    hasPendingTransaction.value = pendingTransaction != nil
  }
  
  func didTapHistoryButton() {
    AppDependencies.router.openTransactionHistory()
  }
}

//extension EarnOverViewModel {
//  private func observeNotifications() {
//    NotificationCenter.default.addObserver(
//      self,
//      selector: #selector(appDidSwitchAddress),
//      name: AppEventCenter.shared.kAppDidChangeAddress,
//      object: nil
//    )
//    NotificationCenter.default.addObserver(
//      self,
//      selector: #selector(self.transactionStateDidUpdate),
//      name: Notification.Name(kTransactionDidUpdateNotificationKey),
//      object: nil
//    )
//  }
//
//  func appDidSwitchChain() {
//    checkPendingTx()
//  }
//
//  @objc func appDidSwitchAddress() {
//    checkPendingTx()
//  }
//
//  @objc func transactionStateDidUpdate() {
//    checkPendingTx()
//  }
//}
