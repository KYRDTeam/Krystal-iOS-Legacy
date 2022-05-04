//
//  KNTransactionHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 21/04/2022.
//

import Foundation

enum KNTransactionHistoryType {
  case krystal
  case `internal`
  case solana
}

struct KNTransactionHistoryViewModelActions {
  var closeTransactionHistory: () -> ()
  var openTransactionFilter: ([String], KNTransactionFilter) -> ()
  var openTransactionDetail: (TransactionHistoryItem) -> ()
  var openPendingTransactionDetail: (InternalHistoryTransaction) -> ()
  var openSwap: () -> ()
  var speedupTransaction: (InternalHistoryTransaction) -> ()
  var cancelTransaction: (InternalHistoryTransaction) -> ()
  var openWalletSelectPopup: () -> ()
  var onUpdateWallet: (KNWalletObject) -> ()
}

class KNTransactionHistoryViewModel {
  fileprivate(set) var tokens: [String] = []
  fileprivate(set) var currentWallet: KNWalletObject
  fileprivate(set) var filters: KNTransactionFilter!
  var actions: KNTransactionHistoryViewModelActions?
  var type: KNTransactionHistoryType
  
  var tokenSymbols: [String] {
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols()
    }
    return EtherscanTransactionStorage.shared.getEtherscanToken().map { $0.symbol }
  }
  
  var hasPendingTransactions: Bool {
    return !EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty
  }

  init(currentWallet: KNWalletObject, type: KNTransactionHistoryType) {
    self.currentWallet = currentWallet
    self.type = type
    self.tokens = tokenSymbols
    self.filters = KNTransactionFilter(
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
      tokens: []
    )
  }

  func updateCurrentWallet(_ currentWallet: KNWalletObject) {
    self.currentWallet = currentWallet
    actions?.onUpdateWallet(currentWallet)
  }
  
  func didTapBack() {
    actions?.closeTransactionHistory()
  }
  
  func didTapSwap() {
    actions?.openSwap()
  }
  
  func didTapFilter() {
    actions?.openTransactionFilter(tokenSymbols, filters)
  }
  
  func didSelectTransaction(transaction: TransactionHistoryItem) {
    actions?.openTransactionDetail(transaction)
  }

  func didSelectPendingTransaction(transaction: InternalHistoryTransaction) {
    actions?.openTransactionDetail(transaction)
  }
  
  func didSelectSpeedupTransaction(transaction: InternalHistoryTransaction) {
    actions?.speedupTransaction(transaction)
  }
  
  func didSelectCancelTransaction(transaction: InternalHistoryTransaction) {
    actions?.cancelTransaction(transaction)
  }
  
  func didTapSelectWallet() {
    actions?.openWalletSelectPopup()
  }
  
}
