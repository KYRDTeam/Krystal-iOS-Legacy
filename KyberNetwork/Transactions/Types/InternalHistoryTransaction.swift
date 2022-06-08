//
//  InternalHistoryTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import BigInt

class InternalHistoryTransaction: Codable {
  var hash: String = ""
  var type: HistoryModelType
  var time: Date = Date()
  var nonce: Int = -1
  var state: InternalTransactionState
  let fromSymbol: String?
  let toSymbol: String?
  var transactionDescription: String
  let transactionDetailDescription: String
  var transactionSuccessDescription: String?
  var earnTransactionSuccessDescription: String?
  var tokenAddress: String?
  var transactionObject: SignTransactionObject?
  var toAddress: String?
  var eip1559Transaction: EIP1559Transaction?
  let chain: ChainType
  var extraData: InternalHistoryExtraData?

  init(
    type: HistoryModelType,
    state: InternalTransactionState,
    fromSymbol: String?,
    toSymbol: String?,
    transactionDescription: String,
    transactionDetailDescription: String,
    transactionObj: SignTransactionObject?,
    eip1559Tx: EIP1559Transaction?,
    extraData: InternalHistoryExtraData? = nil
  ) {
    self.type = type
    self.state = state
    self.fromSymbol = fromSymbol
    self.toSymbol = toSymbol
    self.transactionDescription = transactionDescription
    self.transactionDetailDescription = transactionDetailDescription
    self.transactionObject = transactionObj
    self.eip1559Transaction = eip1559Tx
    self.chain = KNGeneralProvider.shared.currentChain
  }
  
  var gasFee: BigInt {
    guard let transactionObject = transactionObject else {
      return BigInt(0)
    }
    let gasPrice = BigInt(transactionObject.gasPrice) ?? BigInt(0)
    let gasLimit = BigInt(transactionObject.gasLimit) ?? BigInt(0)
    return gasPrice * gasLimit
  }
  
  func acceptExtraData(extraData: InternalHistoryExtraData?) {
    if self.extraData == nil {
      self.extraData = extraData
      return
    }
    guard let extraData = extraData else {
      return
    }
    self.extraData?.crosschainStatus = extraData.crosschainStatus
    if extraData.from?.txStatus.lowercased() == "success" {
      self.extraData?.from = extraData.from
    }
    if extraData.to?.txStatus.lowercased() == "success" {
      self.extraData?.to = extraData.to
    }
  }
}

struct InternalHistoryExtraData: Codable {
  
  var from: ExtraBridgeTransaction?
  var to: ExtraBridgeTransaction?
  var type: String
  var crosschainStatus: String
  
  var isSuccess: Bool {
    return crosschainStatus.lowercased() == "success"
  }

}
