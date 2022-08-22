//
//  TxBasedSwapGasLimitLoader.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/08/2022.
//

import Foundation
import BigInt
import Moya

class TxBasedSwapGasLimitLoader: SwapGasLimitLoader {
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
  var tx: RawSwapTransaction
  
  init(rawTx: RawSwapTransaction) {
    self.tx = rawTx
  }
  
  func getGasLimit(completion: @escaping (_ gasLimit: BigInt?) -> ()) {
    provider.requestWithFilter(.buildSwapTx(address: tx.userAddress, src: tx.src, dst: tx.dest, srcAmount: tx.srcQty, minDstAmount: tx.minDesQty, gasPrice: tx.gasPrice, nonce: tx.nonce, hint: tx.hint, useGasToken: tx.useGasToken)) { result in
      switch result {
      case .success(let response):
        do {
          let data = try JSONDecoder().decode(TransactionResponse.self, from: response.data)
          let gasLimit = BigInt(data.txObject.gasLimit.drop0x, radix: 16)
          completion(gasLimit)
        } catch {
          completion(nil)
        }
      case .failure:
        completion(nil)
      }
    }
  }
  
}
