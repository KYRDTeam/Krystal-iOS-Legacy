//
//  KNHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation
import UIKit

class KNHistoryViewModel {
  
  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()

  fileprivate(set) var tokens: [Token]
  fileprivate(set) var currentWallet: KNWalletObject
  fileprivate(set) var isShowingPending: Bool = true
  fileprivate(set) var filters: KNTransactionFilter!
  
  fileprivate(set) var displayingCompletedKrystalTxData: [String: [CompletedKrystalHistoryTransactionViewModel]] = [:]
  fileprivate(set) var displayingCompletedKrystalTxHeaders: [String] = []
  
  fileprivate(set) var displayingUnsupportedChainCompletedTxHeaders: [String] = []
  fileprivate(set) var displayingUnsupportedChainCompletedTxData: [String: [PendingInternalHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingPendingTxData: [String: [PendingInternalHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingPendingTxHeaders: [String] = []

  init(
    tokens: [Token] = EtherscanTransactionStorage.shared.getEtherscanToken(),
    currentWallet: KNWalletObject
  ) {
    self.tokens = tokens
    self.currentWallet = currentWallet
    self.isShowingPending = true
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
      tokens: self.tokensSymbol
    )
    self.reloadAllData()
  }

  func updateIsShowingPending(_ isShowingPending: Bool) {
    self.isShowingPending = isShowingPending
  }

  func update(tokens: [Token]) {
    self.tokens = tokens
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
      tokens: self.tokensSymbol
    )
    self.reloadAllData()
  }

  func updateCurrentWallet(_ currentWallet: KNWalletObject) {
    self.currentWallet = currentWallet
  }

  var isEmptyStateHidden: Bool {
    if self.isShowingPending {
      return !self.displayingPendingTxHeaders.isEmpty
    } else if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return !self.displayingUnsupportedChainCompletedTxHeaders.isEmpty
    }
    return !self.displayingCompletedKrystalTxHeaders.isEmpty
  }

  var isRateMightChangeHidden: Bool {
    return true
  }

  var transactionCollectionViewBottomPaddingConstraint: CGFloat {
    return self.isRateMightChangeHidden ? 0.0 : 192.0
  }

  var isTransactionCollectionViewHidden: Bool {
    return !self.isEmptyStateHidden
  }
  
  var tokensSymbol: [String] {
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols()
    }
    return self.tokens.map({ return $0.symbol })
  }

  var numberSections: Int {
    if self.isShowingPending { return self.displayingPendingTxHeaders.count }
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return self.displayingUnsupportedChainCompletedTxHeaders.count
    }
    return self.displayingCompletedKrystalTxHeaders.count
  }

  func header(for section: Int) -> String {
    let header: String = {
      if self.isShowingPending {
        return self.displayingPendingTxHeaders[section]
      } else if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        return self.displayingUnsupportedChainCompletedTxHeaders[section]
      }
      return self.displayingCompletedKrystalTxHeaders[section]
    }()
    return header
  }

  func numberRows(for section: Int) -> Int {
    let header = self.header(for: section)
    if self.isShowingPending {
      return self.displayingPendingTxData[header]?.count ?? 0
    } else {
      if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        return self.displayingUnsupportedChainCompletedTxData[header]?.count ?? 0
      }
      return self.displayingCompletedKrystalTxData[header]?.count ?? 0
    }
  }

  func completedTransaction(for row: Int, at section: Int) -> AbstractHistoryTransactionViewModel? {
    let header = self.header(for: section)
    if let trans = self.displayingCompletedKrystalTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  func pendingTransaction(for row: Int, at section: Int) -> PendingInternalHistoryTransactonViewModel? {
    let header = self.header(for: section)
    if let trans = self.displayingPendingTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  func completeTransactionForUnsupportedChain(for row: Int, at section: Int) -> PendingInternalHistoryTransactonViewModel? {
    let header = self.header(for: section)
    if let trans = self.displayingUnsupportedChainCompletedTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  fileprivate func isInternalHistoryTransactionIncluded(_ tx: InternalHistoryTransaction) -> Bool {
    var isMatchingConditions = true
    
    if let from = filters.from {
      isMatchingConditions = isMatchingConditions && tx.time >= from.startDate()
    }
    if let to = filters.to {
      isMatchingConditions = isMatchingConditions && tx.time < to.endDate()
    }
    
    let matchedTransfer = (tx.type == .transferETH || tx.type == .transferNFT || tx.type == .transferToken) && self.filters.isSend
    let matchedReceive = (tx.type == .receiveETH || tx.type == .receiveNFT || tx.type == .receiveToken) && self.filters.isReceive
    let matchedSwap = (tx.type == .swap) && self.filters.isSwap
    let matchedAppprove = (tx.type == .allowance) && self.filters.isApprove
    let matchedSupply = (tx.type == .earn) && self.filters.isTrade
    let matchedWithdraw = (tx.type == .withdraw) && self.filters.isWithdraw
    let matchedClaimReward = (tx.type == .claimReward) && self.filters.isClaimReward
    let matchedContractInteraction = (tx.type == .contractInteraction) && self.filters.isContractInteraction
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward

    isMatchingConditions = isMatchingConditions && matchedType
    
    let txTokens = [
      tx.fromSymbol,
      tx.toSymbol
    ].compactMap { $0 }
    
    if txTokens.isEmpty {
      isMatchingConditions = isMatchingConditions && self.filters.tokens.count == EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols().count
    } else {
      isMatchingConditions = isMatchingConditions && filters.tokens.containsElementsOf(other: txTokens)
    }
    return isMatchingConditions
  }

  fileprivate func isCompletedKrystalTransactionIncluded(_ tx: KrystalHistoryTransaction) -> Bool {
    var isMatchingConditions = true
    
    if let from = filters.from {
      isMatchingConditions = isMatchingConditions && tx.date >= from.startDate()
    }
    if let to = filters.to {
      isMatchingConditions = isMatchingConditions && tx.date < to.endDate()
    }
    
    let matchedTransfer = (tx.type == "Transfer") && self.filters.isSend
    let matchedReceive = (tx.type == "Received") && self.filters.isReceive
    let matchedSwap = (tx.type == "Swap") && self.filters.isSwap
    let matchedAppprove = (tx.type == "Approval") && self.filters.isApprove
    let matchedSupply = (tx.type == "Supply") && self.filters.isTrade
    let matchedWithdraw = (tx.type == "Withdraw") && self.filters.isWithdraw
    let matchedClaimReward = (tx.type == "ClaimReward") && self.filters.isClaimReward
    let matchedContractInteraction = (tx.type == "" || tx.type == "ContractInteration") && self.filters.isContractInteraction
    
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward

    isMatchingConditions = isMatchingConditions && matchedType
        
    let txTokens = [
      tx.extraData?.token?.symbol,
      tx.extraData?.sendToken?.symbol,
      tx.extraData?.receiveToken?.symbol
    ].compactMap { $0 }
    
    if txTokens.isEmpty {
      // True when filter all tokens
      isMatchingConditions = isMatchingConditions && filters.tokens.count == EtherscanTransactionStorage.shared.getEtherscanToken().count
    } else {
      isMatchingConditions = isMatchingConditions && filters.tokens.containsElementsOf(other: txTokens)
    }
    
    return isMatchingConditions
  }

  var normalAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.white,
  ]

  var selectedAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.Kyber.enygold,
  ]

  func updateFilters(_ filters: KNTransactionFilter) {
    self.filters = filters
    self.reloadAllData()
    KNAppTracker.saveHistoryFilterData(filters)
  }

  var isShowingQuickTutorial: Bool = false

  var timeForLongPendingTx: Double {
    return KNEnvironment.default == .ropsten ? 30.0 : 300
  }

  var isShowQuickTutorialForLongPendingTx: Bool {
    return UserDefaults.standard.bool(forKey: Constants.kisShowQuickTutorialForLongPendingTx)
  }
  
  func reloadAllData() {
    reloadCompletedTransactions()
    reloadPendingTransactions()
  }
  
  func reloadCompletedTransactions() {
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      reloadInternalCompletedTransactions()
    } else {
      reloadKrystalTransactions()
    }
  }
  
  func reloadKrystalTransactions() {
    let filteredTxs = EtherscanTransactionStorage.shared
      .getKrystalTransaction()
      .filter(isCompletedKrystalTransactionIncluded)
    
    self.displayingCompletedKrystalTxHeaders = filteredTxs
      .map { $0.date }
      .sorted(by: >)
      .map { dateFormatter.string(from: $0) }
      .unique
    
    let completedKrystalTxData: [String: [KrystalHistoryTransaction]] = Dictionary(grouping: filteredTxs) { dateFormatter.string(from: $0.date) }
    self.displayingCompletedKrystalTxData = completedKrystalTxData.mapValues { txs in
      return txs
        .sorted { $0.date > $1.date }
        .map(CompletedKrystalHistoryTransactionViewModel.init)
    }
  }
  
  func reloadPendingTransactions() {
    let filteredPendingTxs = EtherscanTransactionStorage.shared
      .getInternalHistoryTransaction()
      .filter(isInternalHistoryTransactionIncluded)
    
    self.displayingPendingTxHeaders = filteredPendingTxs
      .map { $0.time }
      .sorted(by: >)
      .map { dateFormatter.string(from: $0) }
      .unique
    
    let pendingTxData: [String: [InternalHistoryTransaction]] = Dictionary(grouping: filteredPendingTxs) { dateFormatter.string(from: $0.time) }
    self.displayingPendingTxData = pendingTxData.mapValues { txs in
      return txs
        .sorted { $0.time > $1.time }
        .map(PendingInternalHistoryTransactonViewModel.init)
    }
  }
  
  private func reloadInternalCompletedTransactions() {
    let filteredCompletedTxs = EtherscanTransactionStorage.shared
      .getHandledInternalHistoryTransactionForUnsupportedApi()
      .filter(isInternalHistoryTransactionIncluded)
    
    self.displayingUnsupportedChainCompletedTxHeaders = filteredCompletedTxs
      .map { $0.time }
      .sorted(by: >)
      .map { dateFormatter.string(from: $0) }
      .unique
    
    let handledTxData: [String: [InternalHistoryTransaction]] = Dictionary(grouping: filteredCompletedTxs) { dateFormatter.string(from: $0.time) }
    self.displayingUnsupportedChainCompletedTxData = handledTxData.mapValues { txs in
      return txs
        .sorted { $0.time > $1.time }
        .map(PendingInternalHistoryTransactonViewModel.init)
    }
  }
}
