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
  
  enum TransactionType {
    case completed(tx: KrystalHistoryTransaction)
    case pending(tx: InternalHistoryTransaction)
  }
  
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
  }
  
  func getTransactionType(txType: String) -> TransactionHistoryItemType {
    return TransactionHistoryItemType(rawValue: txType) ?? .contractInteraction
  }
  
  func getTransactionItems(tx: KrystalHistoryTransaction) -> [TransactionDetailRowType] {
    let type = getTransactionType(txType: tx.type)
    switch type {
    case .bridgeFrom, .bridgeTo:
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
        .common(type: .bridgeFrom, timestamp: Int(internalTx.time.timeIntervalSince1970)),
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
}
