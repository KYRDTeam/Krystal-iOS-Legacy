//
//  KNHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 11/02/2022.
//

import UIKit

struct KNHistoryViewModel {
  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()

  fileprivate(set) var tokens: [Token]

  fileprivate(set) var completedKrystalTxData: [String: [KrystalHistoryTransaction]] = [:]
  fileprivate(set) var completedKrystalTxHeaders: [String] = []

  fileprivate(set) var displayingCompletedKrystalTxData: [String: [CompletedKrystalHistoryTransactionViewModel]] = [:]
  fileprivate(set) var displayingCompletedKrystalTxHeaders: [String] = []
  
  fileprivate(set) var displayingUnsupportedChainCompletedTxHeaders: [String] = []
  fileprivate(set) var displayingUnsupportedChainCompletedTxData: [String: [PendingInternalHistoryTransactonViewModel]] = [:]

  fileprivate(set) var displayingCompletedTxData: [String: [CompletedHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingCompletedTxHeaders: [String] = []

  fileprivate(set) var pendingTxData: [String: [InternalHistoryTransaction]] = [:]
  fileprivate(set) var pendingTxHeaders: [String] = []

  fileprivate(set) var handledTxData: [String: [InternalHistoryTransaction]] = [:]
  fileprivate(set) var handledTxHeaders: [String] = []

  fileprivate(set) var displayingPendingTxData: [String: [PendingInternalHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingPendingTxHeaders: [String] = []

  fileprivate(set) var currentWallet: KNWalletObject

  fileprivate(set) var isShowingPending: Bool = true

  fileprivate(set) var filters: KNTransactionFilter!

  init(
    tokens: [Token] = HistoryTransactionStorage.shared.getEtherscanToken(),
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
    self.updateDisplayingData()
  }

  mutating func updateIsShowingPending(_ isShowingPending: Bool) {
    self.isShowingPending = isShowingPending
  }

  mutating func update(tokens: [Token]) {
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
    self.updateDisplayingData()
  }

  mutating func update(completedKrystalTxData: [String: [KrystalHistoryTransaction]], completedKrystalTxHeaders: [String]) {
    self.completedKrystalTxData = completedKrystalTxData
    self.completedKrystalTxHeaders = completedKrystalTxHeaders
    self.updateDisplayingData(isPending: false)
  }

  mutating func update(pendingTxData: [String: [InternalHistoryTransaction]], pendingTxHeaders: [String]) {
    self.pendingTxData = pendingTxData
    self.pendingTxHeaders = pendingTxHeaders
    self.updateDisplayingData(isCompleted: false)
  }

  mutating func update(handledTxData: [String: [InternalHistoryTransaction]], handledTxHeaders: [String]) {
    self.handledTxData = handledTxData
    self.handledTxHeaders = handledTxHeaders
    self.updateDisplayingData(isCompleted: false)
  }

  mutating func updateCurrentWallet(_ currentWallet: KNWalletObject) {
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

  var emptyStateIconName: String {
    return self.isShowingPending ? "no_pending_tx_icon" : "no_mined_tx_icon"
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
      return HistoryTransactionStorage.shared.getInternalHistoryTokenSymbols()
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

  mutating func updateDisplayingKrystalData() {
    let fromDate = self.filters.from ?? Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    let toDate = self.filters.to ?? Date().addingTimeInterval(24.0 * 60.0 * 60.0)
    let displayHeaders: [String] = {
      let data = self.completedKrystalTxHeaders.filter({
        let date = self.dateFormatter.date(from: $0) ?? Date()
        return date >= fromDate.startDate() && date < toDate.endDate()
      })
      return data
    }()
    self.displayingCompletedKrystalTxData = [:]
    displayHeaders.forEach { (header) in
      let items = self.completedKrystalTxData[header]?.filter({ return self.isCompletedKrystalTransactionIncluded($0) }).enumerated().map { (item) -> CompletedKrystalHistoryTransactionViewModel in
        return CompletedKrystalHistoryTransactionViewModel(item: item.1)
      } ?? []
      self.displayingCompletedKrystalTxData[header] = items
    }
    let filtered = displayHeaders.filter { (header) -> Bool in
      return !(self.displayingCompletedKrystalTxData[header]?.isEmpty ?? false)
    }
    self.displayingCompletedKrystalTxHeaders = filtered
  }

  mutating func updateDisplayingData(isPending: Bool = true, isCompleted: Bool = true) {
    let fromDate = self.filters.from ?? Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    let toDate = self.filters.to ?? Date().addingTimeInterval(24.0 * 60.0 * 60.0)

    if isPending {
      self.displayingPendingTxHeaders = {
        let data = self.pendingTxHeaders.filter({
          let date = self.dateFormatter.date(from: $0) ?? Date()
          return date >= fromDate.startDate() && date < toDate.endDate()
        })
        return data
      }()
      self.displayingPendingTxData = [:]

      self.displayingPendingTxHeaders.forEach { (header) in
        let filteredPendingTxData = self.pendingTxData[header]?.sorted(by: { $0.time > $1.time })
        let items = filteredPendingTxData?.map({ (item) -> PendingInternalHistoryTransactonViewModel in
          return PendingInternalHistoryTransactonViewModel(index: 0, transaction: item)
        })
        self.displayingPendingTxData[header] = items
      }
    }

    if isCompleted {
      if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        self.displayingUnsupportedChainCompletedTxHeaders = {
          let data = self.handledTxHeaders.filter({
            let date = self.dateFormatter.date(from: $0) ?? Date()
            return date >= fromDate.startDate() && date < toDate.endDate()
          }).sorted { date1String, date2String in
            let date1 = self.dateFormatter.date(from: date1String) ?? Date()
            let date2 = self.dateFormatter.date(from: date2String) ?? Date()
            return date1 > date2
          }
          return data
        }()
        self.displayingUnsupportedChainCompletedTxData = [:]
        self.displayingUnsupportedChainCompletedTxHeaders.forEach { (header) in
          let filteredHandledTxData = self.handledTxData[header]?.sorted(by: { $0.time > $1.time })
          let items = filteredHandledTxData?.filter({ return self.isInternalHistoryTransactionIncluded($0) }).map({ (item) -> PendingInternalHistoryTransactonViewModel in
            return PendingInternalHistoryTransactonViewModel(index: 0, transaction: item)
          })
          self.displayingUnsupportedChainCompletedTxData[header] = items
        }
      } else {
        self.updateDisplayingKrystalData()
      }
    }
  }

  fileprivate func isInternalHistoryTransactionIncluded(_ tx: InternalHistoryTransaction) -> Bool {
    let matchedTransfer = (tx.type == .transferETH || tx.type == .transferNFT || tx.type == .transferToken) && self.filters.isSend
    let matchedReceive = (tx.type == .receiveETH || tx.type == .receiveNFT || tx.type == .receiveToken) && self.filters.isReceive
    let matchedSwap = (tx.type == .swap) && self.filters.isSwap
    let matchedAppprove = (tx.type == .allowance) && self.filters.isApprove
    let matchedSupply = (tx.type == .earn) && self.filters.isTrade
    let matchedWithdraw = (tx.type == .withdraw) && self.filters.isWithdraw
    let matchedClaimReward = (tx.type == .claimReward) && self.filters.isClaimReward
    let matchedContractInteraction = (tx.type == .contractInteraction) && self.filters.isContractInteraction
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward

    var tokenMatched = false
    var transactionToken: [String] = []
    if let sym = tx.fromSymbol {
      transactionToken.append(sym)
    }
    if let sym = tx.toSymbol {
      transactionToken.append(sym)
    }
    if transactionToken.isEmpty && self.filters.tokens.count == HistoryTransactionStorage.shared.getInternalHistoryTokenSymbols().count {
      tokenMatched = true
    } else {
      transactionToken.forEach { transaction in
        if self.filters.tokens.contains(transaction) {
          tokenMatched = true
        }
      }
    }
    return matchedType && tokenMatched
  }

  fileprivate func isCompletedKrystalTransactionIncluded(_ tx: KrystalHistoryTransaction) -> Bool {
    let matchedTransfer = (tx.type == "Transfer") && self.filters.isSend
    let matchedReceive = (tx.type == "Received") && self.filters.isReceive
    let matchedSwap = (tx.type == "Swap") && self.filters.isSwap
    let matchedAppprove = (tx.type == "Approval") && self.filters.isApprove
    let matchedSupply = (tx.type == "Supply") && self.filters.isTrade
    let matchedWithdraw = (tx.type == "Withdraw") && self.filters.isWithdraw
    let matchedClaimReward = (tx.type == "ClaimReward") && self.filters.isClaimReward
    let matchedContractInteraction = (tx.type == "" || tx.type == "ContractInteration") && self.filters.isContractInteraction
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward

    var tokenMatched = false
    var transactionToken: [String] = []
    if let sym = tx.extraData?.token?.symbol {
      transactionToken.append(sym)
    }
    if let sym = tx.extraData?.sendToken?.symbol {
      transactionToken.append(sym)
    }
    if let sym = tx.extraData?.receiveToken?.symbol {
      transactionToken.append(sym)
    }
    if transactionToken.isEmpty && self.filters.tokens.count == HistoryTransactionStorage.shared.getEtherscanToken().count {
      tokenMatched = true
    } else {
      transactionToken.forEach { transaction in
        if self.filters.tokens.contains(transaction) {
          tokenMatched = true
        }
      }
    }
    return matchedType && tokenMatched
  }

  var normalAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.white,
  ]

  var selectedAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.Kyber.enygold,
  ]

  mutating func updateFilters(_ filters: KNTransactionFilter) {
    self.filters = filters
    self.updateDisplayingData()
    KNAppTracker.saveHistoryFilterData(filters)
  }

  var isShowingQuickTutorial: Bool = false

  var timeForLongPendingTx: Double {
    return KNEnvironment.default == .ropsten ? 30.0 : 300
  }

  var isShowQuickTutorialForLongPendingTx: Bool {
    return UserDefaults.standard.bool(forKey: Constants.kisShowQuickTutorialForLongPendingTx)
  }
}
