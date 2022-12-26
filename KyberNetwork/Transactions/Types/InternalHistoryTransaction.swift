//
//  InternalHistoryTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import BigInt
import BaseWallet

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
  var chain: ChainType
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
    extraData: InternalHistoryExtraData? = nil,
    chain: ChainType = KNGeneralProvider.shared.currentChain
  ) {
    self.type = type
    self.state = state
    self.fromSymbol = fromSymbol
    self.toSymbol = toSymbol
    self.transactionDescription = transactionDescription
    self.transactionDetailDescription = transactionDetailDescription
    self.transactionObject = transactionObj
    self.eip1559Transaction = eip1559Tx
    self.chain = chain
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
    if let from = extraData.from, ExtraData.terminatedStatuses.contains(from.txStatus.lowercased()) {
      self.extraData?.from = from
    }
    if let to = extraData.to, ExtraData.terminatedStatuses.contains(to.txStatus.lowercased()) {
      self.extraData?.to = extraData.to
    }
  }
  
  var transactionGasPrice: String {
    if let tx = transactionObject {
      return tx.gasPrice
    } else if let tx = eip1559Transaction {
      return tx.maxGasFee
    } else {
      return ""
    }
  }
  
  var transactionGasPriceBigInt: BigInt {
    return BigInt(self.transactionGasPrice) ?? .zero
  }
  
  var speedupGasBigInt: BigInt {
    var speedupGas = self.transactionGasPriceBigInt
    speedupGas += (speedupGas * 20 / 100) //Add 10%
    return speedupGas
  }
}

struct InternalHistoryExtraData: Codable {
  
  var from: ExtraBridgeTransaction?
  var to: ExtraBridgeTransaction?
  var type: String
  var crosschainStatus: String
  
  var isCompleted: Bool {
    return ExtraData.terminatedStatuses.contains(crosschainStatus.lowercased())
  }

}
