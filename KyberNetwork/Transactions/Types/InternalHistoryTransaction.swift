//
//  InternalHistoryTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

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

  init(
    type: HistoryModelType,
    state: InternalTransactionState,
    fromSymbol: String?,
    toSymbol: String?,
    transactionDescription: String,
    transactionDetailDescription: String,
    transactionObj: SignTransactionObject?,
    eip1559Tx: EIP1559Transaction?) {
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
}
