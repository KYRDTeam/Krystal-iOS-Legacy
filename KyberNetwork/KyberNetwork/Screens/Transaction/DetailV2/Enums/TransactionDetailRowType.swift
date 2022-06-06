//
//  TransactionDetailItemType.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/05/2022.
//

import Foundation

enum TransactionDetailRowType {
  case common(type: TransactionHistoryItemType, timestamp: Int)
  case bridgeSubTx(from: Bool, tx: ExtraBridgeTransaction)
  case stepSeparator
  case bridgeFee(fee: String)
  case estimatedBridgeTime(time: String)
}

extension TransactionDetailRowType: Equatable {
  static func == (lhs: TransactionDetailRowType, rhs: TransactionDetailRowType) -> Bool {
    switch (lhs, rhs) {
    case (.common(let lhsType, let lhsTimestamp), .common(let rhsType, let rhsTimestamp)):
      return lhsType == rhsType && lhsTimestamp == rhsTimestamp
    case (.bridgeSubTx(let lhsIsFrom, let lhsTx), .bridgeSubTx(let rhsIsFrom, let rhsTx)):
      return lhsIsFrom == rhsIsFrom && lhsTx.tx == rhsTx.tx
    case (.stepSeparator, .stepSeparator):
      return true
    case (.bridgeFee(let lhsFee), .bridgeFee(let rhsFee)):
      return lhsFee == rhsFee
    case (.estimatedBridgeTime(let lhsTime), .estimatedBridgeTime(let rhsTime)):
      return lhsTime == rhsTime
    default:
      return false
    }
  }
  
}
