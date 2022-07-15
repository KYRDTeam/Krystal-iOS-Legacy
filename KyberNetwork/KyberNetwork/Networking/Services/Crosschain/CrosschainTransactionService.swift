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
  var pendingTxHashes: [String] = []
  
  deinit {
    timer?.invalidate()
    timer = nil
  }
  
  func cancelScheduledFetching() {
    pendingTxHashes = []
    timer?.invalidate()
    timer = nil
  }
  
  func addPendingTxHash(txHash: String) {
    if !pendingTxHashes.contains(txHash) {
      self.pendingTxHashes.append(txHash)
    }
    refreshPendingTransactionStatus()
  }
  
  func scheduleFetchPendingTransaction() {
    refreshPendingTransactionStatus()
    timer = Timer.scheduledTimer(withTimeInterval: KNLoadingInterval.seconds15, repeats: true, block: { [weak self] _ in
      self?.refreshPendingTransactionStatus()
    })
  }
  
  func refreshPendingTransactionStatus() {
    guard let txHash = pendingTxHashes.last else { return }
    getTransactionStatus(txHash: txHash, chainId: "\(KNGeneralProvider.shared.currentChain.getChainId())") { [weak self] extraData in
      guard let extraData = extraData else {
        return
      }
      if extraData.from?.isCompleted == true, extraData.to?.isCompleted == true {
        self?.pendingTxHashes.removeAll { $0 == txHash }
      }
      var userInfo: [String: Any] = [:]
      userInfo["extraData"] = extraData
      userInfo["txHash"] = txHash
      KNNotificationUtil.postNotification(
        for: kBridgeExtraDataUpdateNotificationKey,
        object: nil,
        userInfo: userInfo
      )
    }
  }
  
  func getTransactionStatus(txHash: String, chainId: String, completion: @escaping (InternalHistoryExtraData?) -> ()) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
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
