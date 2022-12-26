// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt
import TrustCore
import TrustKeystore
import Result

extension SignTransaction {
  
    init(value: BigInt, account: Account, to: String?, nonce: Int, data: Data, gasPrice: BigInt, gasLimit: BigInt, chainID: Int) {
        self.init(value: value, address: account.address.description, to: to, nonce: nonce, data: data, gasPrice: gasPrice, gasLimit: gasLimit, chainID: chainID)
    }
    
}


extension SignTransaction {
  func toSignTransactionObject() -> SignTransactionObject {
    return SignTransactionObject(value: self.value.description, from: address, to: self.to, nonce: self.nonce, data: self.data, gasPrice: self.gasPrice.description, gasLimit: self.gasLimit.description, chainID: self.chainID, reservedGasLimit: self.gasLimit.description)
  }
}

extension SignTransaction {
  func toTransaction(hash: String, fromAddr: String, type: TransactionType = .earn) -> Transaction {
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: fromAddr,
      to: self.to?.description ?? "",
      value: self.value.description,
      gas: self.gasLimit.description,
      gasPrice: self.gasPrice.description,
      gasUsed: self.gasLimit.description,
      nonce: "\(self.nonce)",
      date: Date(),
      localizedOperations: [],
      state: .pending,
      type: type
    )
  }
}

extension SignTransaction: GasLimitRequestable {
  func createGasLimitRequest() -> KNEstimateGasLimitRequest {
    let request = KNEstimateGasLimitRequest(
      from: address,
      to: self.to?.description,
      value: self.value,
      data: self.data,
      gasPrice: self.gasPrice
    )
    return request
  }
}
