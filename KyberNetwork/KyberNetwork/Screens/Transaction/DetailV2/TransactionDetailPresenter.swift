//
//  TransactionDetailPresenter.swift
//  KyberNetwork
//
//  Created Nguyen Tung on 19/05/2022.
//  Copyright © 2022 Krystal. All rights reserved.
//

import BigInt

class TransactionDetailPresenter: TransactionDetailPresenterProtocol {
  private var interactor: TransactionDetailInteractorProtocol
  private var router: TransactionDetailRouterProtocol
  weak var view: TransactionDetailViewProtocol!
  let crosschainTxService = CrosschainTransactionService()
  
  var items: [TransactionDetailRowType] = []
  let minEstimatedTimeInMinutes = 9
  let maxEstimatedTimeInMinutes = 30
  var txHash: String = ""
  
  init(view: TransactionDetailViewProtocol, interactor: TransactionDetailInteractorProtocol, router: TransactionDetailRouterProtocol) {
    self.interactor = interactor
    self.router = router
    self.view = view
  }

  func setupTransaction(tx: KrystalHistoryTransaction) {
    self.txHash = tx.txHash
    self.items = getTransactionItems(tx: tx)
  }
  
  func setupTransaction(internalTx: InternalHistoryTransaction) {
    self.txHash = internalTx.txHash
    self.items = getTransactionItems(internalTx: internalTx)
    self.observeTxStatus()
  }
  
  func getTransactionType(txType: String) -> TransactionHistoryItemType {
    return TransactionHistoryItemType(rawValue: txType) ?? .contractInteraction
  }
  
  func getTransactionItems(tx: KrystalHistoryTransaction) -> [TransactionDetailRowType] {
    let type = getTransactionType(txType: tx.type)
    switch type {
    case .bridge:
      guard let from = tx.extraData?.from, let to = tx.extraData?.to else {
        return []
      }
      let quoteToken = getChain(chainID: from.chainId)?.quoteToken() ?? ""
      let bridgeFee = BigInt(tx.gasCost)?.fullString(decimals: 18) ?? "0"
      var rows: [TransactionDetailRowType] = [
        .common(type: type, timestamp: tx.timestamp),
        .bridgeSubTx(from: true, tx: from),
        .stepSeparator,
        .bridgeSubTx(from: false, tx: to),
        .bridgeFee(fee: bridgeFee + " " + quoteToken)
      ]
      let fromStatus = TransactionStatus(status: from.txStatus)
      let toStatus = TransactionStatus(status: to.txStatus)
      if !isTxCompleted(fromStatus: fromStatus, toStatus: toStatus) {
        let timeString = String(format: Strings.xMins,
                                "\(minEstimatedTimeInMinutes)-\(maxEstimatedTimeInMinutes)")
        rows.append(.estimatedBridgeTime(time: timeString))
      }
      return rows
    default:
      return []
    }
  }
  
  func getTransactionItems(internalTx: InternalHistoryTransaction) -> [TransactionDetailRowType] {
    switch internalTx.type {
    case .bridge:
      guard let from = internalTx.extraData?.from, let to = internalTx.extraData?.to else {
        return []
      }
      let quoteToken = getChain(chainID: from.chainId)?.quoteToken() ?? ""
      let bridgeFee = internalTx.gasFee.fullString(decimals: 18)
      var rows: [TransactionDetailRowType] = [
        .common(type: .bridge, timestamp: Int(internalTx.time.timeIntervalSince1970)),
        .bridgeSubTx(from: true, tx: from),
        .stepSeparator,
        .bridgeSubTx(from: false, tx: to),
        .bridgeFee(fee: bridgeFee + " " + quoteToken)
      ]
      let fromStatus = TransactionStatus(status: from.txStatus)
      let toStatus = TransactionStatus(status: to.txStatus)
      if !isTxCompleted(fromStatus: fromStatus, toStatus: toStatus) {
        let timeString = String(format: Strings.xMins,
                                "\(minEstimatedTimeInMinutes)-\(maxEstimatedTimeInMinutes)")
        rows.append(.estimatedBridgeTime(time: timeString))
      }
      return rows
    default:
      return []
    }
  }
  
  func onViewLoaded() {
    view.reloadItems()
  }
  
  func onTapBack() {
    router.goBack()
  }
  
  private func getChain(chainID: String?) -> ChainType? {
    guard let chainID = chainID else {
      return nil
    }

    return ChainType.getAllChain().first { chain in
      chain.customRPC().chainID == Int(chainID)
    }
  }
  
  private func isTxCompleted(fromStatus: TransactionStatus, toStatus: TransactionStatus) -> Bool {
    switch (fromStatus, toStatus) {
    case (.success, .success), (.success, .failure), (.failure, .success), (.failure, .failure):
      return true
    default:
      return false
    }
  }
  
  func onOpenTxScan(txHash: String, chainID: String) {
    guard let endpoint = getChain(chainID: chainID)?.customRPC().etherScanEndpoint else {
      return
    }
    guard let url = URL(string: endpoint + "tx/" + txHash) else {
      return
    }
    router.openTxUrl(url: url)
  }
  
  deinit {
    removeObserver()
  }
  
}

// Support Bridge Transaction
extension TransactionDetailPresenter {
  
  func removeObserver() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
  }
  
  func observeTxStatus() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onBridgeTxUpdate(_:)),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
  }
  
  @objc func onBridgeTxUpdate(_ notification: Notification) {
    if let tx = notification.object as? InternalHistoryTransaction {
      guard tx.txHash == self.txHash else {
        return
      }
      let chainID = KNGeneralProvider.shared.currentChain.getChainId().toString()
      self.crosschainTxService.getTransactionStatus(txHash: txHash, chainId: chainID) { [weak self] extra in
        self?.acceptBridgeExtraData(extra: extra)
      }
    } else if let tx = notification.userInfo?["transaction"] as? InternalHistoryTransaction {
      guard tx.txHash == self.txHash else {
        return
      }
      self.acceptBridgeExtraData(extra: tx.extraData)
    }
  }
  
  func acceptBridgeExtraData(extra: InternalHistoryExtraData?) {
    if let from = extra?.from, from.isCompleted, let index = getFromTxRowIndex(isFrom: true) {
      items[index] = .bridgeSubTx(from: true, tx: from)
    }
    if let to = extra?.to, to.isCompleted, let index = getFromTxRowIndex(isFrom: false) {
      items[index] = .bridgeSubTx(from: false, tx: to)
    }
    view.reloadItems()
  }
  
  private func getFromTxRowIndex(isFrom: Bool) -> Int? {
    return items.firstIndex { rowType in
      switch rowType {
      case .bridgeSubTx(let isFrom, _):
        return isFrom
      default:
        return false
      }
    }
  }
  
}
