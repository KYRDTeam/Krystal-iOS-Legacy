//
//  SolFeeCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 26/04/2022.
//

import Foundation
import BigInt
import Moya

class SolFeeCoordinator {
  static let shared: SolFeeCoordinator = SolFeeCoordinator()
  static let defaultLamportPerSignature = BigInt(5000)
  fileprivate let provider = MoyaProvider<KyberNetworkService>()
  fileprivate var fetchTimer: Timer?

  var lamportPerSignature: BigInt = SolFeeCoordinator.defaultLamportPerSignature

  @objc func fetchSolFee(_ sender: Timer?) {
    DispatchQueue.global(qos: .background).async {
      SolanaUtil.getLamportsPerSignature { lamports in
        if let lamports = lamports {
          self.lamportPerSignature = BigInt(lamports)
        }
      }
    }
  }

  func resume() {
//    self.loadSavedGasPrice()
    fetchTimer?.invalidate()
    fetchSolFee(nil)
    fetchTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.minutes5,
      target: self,
      selector: #selector(fetchSolFee(_:)),
      userInfo: nil,
      repeats: true
    )
  }
}
