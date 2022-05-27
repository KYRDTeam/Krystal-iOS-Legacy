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
  
  var items: [TransactionDetailRowType] = []
  let minEstimatedTimeInMinutes = 9
  let maxEstimatedTimeInMinutes = 30
  
  init(view: TransactionDetailViewProtocol, interactor: TransactionDetailInteractorProtocol, router: TransactionDetailRouterProtocol, tx: KrystalHistoryTransaction) {
    self.interactor = interactor
    self.router = router
    self.view = view
    self.items = getTransactionItems(tx: tx)
  }

  func getTransactionItems(tx: KrystalHistoryTransaction) -> [TransactionDetailRowType] {
    let type = TransactionHistoryItemType(rawValue: tx.type) ?? .contractInteraction
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
