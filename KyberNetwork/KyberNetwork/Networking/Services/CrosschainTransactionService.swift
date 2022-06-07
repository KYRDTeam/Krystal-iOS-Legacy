//
//  CrosschainTransactionService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 06/06/2022.
//

import Foundation
import Moya

class CrosschainTransactionService {
  
  var timer: Timer?
  
  deinit {
    timer?.invalidate()
    timer = nil
  }
  
  func cancelScheduledFetching() {
    timer?.invalidate()
    timer = nil
  }
  
  func scheduleFetchPendingTransaction() {
    timer = Timer.scheduledTimer(withTimeInterval: KNLoadingInterval.seconds15, repeats: true, block: { [weak self] _ in
      self?.refreshPendingTransactionStatus()
    })
  }
  
  func refreshPendingTransactionStatus() {
    let pendingTxs = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().filter { $0.type == .bridge }
    guard let tx = pendingTxs.last else { return }
    getTransactionStatus(txHash: tx.txHash, chainId: "\(tx.chain.getChainId())") { extraData in
      guard let extraData = extraData else {
        return
      }
      if extraData.isSuccess {
        EtherscanTransactionStorage.shared.removeInternalHistoryTransactionWithHash(tx.txHash)
      } else {
        EtherscanTransactionStorage.shared.removeInternalHistoryTransactionWithHash(tx.hash)
        tx.acceptExtraData(extraData: extraData)
        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(tx)
      }
      var userInfo: [String: Any] = [:]
      userInfo["transaction"] = tx
      KNNotificationUtil.postNotification(
        for: kTransactionDidUpdateNotificationKey,
        object: nil,
        userInfo: userInfo
      )
    }
  }
  
  func getTransactionStatus(txHash: String, chainId: String, completion: @escaping (InternalHistoryExtraData?) -> ()) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.checkTxStatus(txHash: txHash, chainId: chainId)) { result in
      switch result {
      case .success(let response):
        do {
          let extra = try JSONDecoder().decode(InternalHistoryExtraData.self, from: response.data)
          completion(extra)
        } catch {
          completion(nil)
        }
      case .failure:
        completion(nil)
      }
    }
  }
  
}
