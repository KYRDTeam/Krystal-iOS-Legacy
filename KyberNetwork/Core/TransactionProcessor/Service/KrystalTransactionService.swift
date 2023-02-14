//
//  KrystalTransactionService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 15/06/2022.
//

import Foundation
import Moya

class KrystalTransactionService {
  
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
  
  func buildSwapTx(tx: RawSwapTransaction, completion: @escaping (TxObject?) -> ()) {
    provider.request(.buildSwapTx(address: tx.userAddress, src: tx.src, dst: tx.dest, srcAmount: tx.srcQty, minDstAmount: tx.minDesQty, gasPrice: tx.gasPrice, nonce: tx.nonce, hint: tx.hint, useGasToken: tx.useGasToken)) { result in
      switch result {
      case .success(let response):
        let data = try? JSONDecoder().decode(TransactionResponse.self, from: response.data)
        completion(data?.txObject)
      default:
        completion(nil)
      }
    }
  }
  
}
