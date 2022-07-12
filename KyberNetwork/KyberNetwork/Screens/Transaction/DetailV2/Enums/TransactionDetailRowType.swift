//
//  TransactionDetailItemType.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/05/2022.
//

import Foundation

enum TransactionDetailRowType {
  case common(type: TransactionHistoryItemType, timestamp: Int, hideStatus: Bool)
  case bridgeSubTx(from: Bool, tx: ExtraBridgeTransaction)
  case stepSeparator
  case bridgeFee(fee: String)
  case estimatedBridgeTime(time: String)
  case multisendHeader(total: Int)
  case multisendTx(index: Int, address: String, amount: String)
  case application(walletAddress: String, applicationAddress: String)
  case txHash(hash: String)
  case transactionFee(fee: String)
}

extension TransactionDetailRowType: Equatable {
  static func == (lhs: TransactionDetailRowType, rhs: TransactionDetailRowType) -> Bool {
    switch (lhs, rhs) {
    case (.common(let lhsType, let lhsTimestamp, let lhsHideStatus), .common(let rhsType, let rhsTimestamp, let rhsHideStatus)):
      return lhsType == rhsType && lhsTimestamp == rhsTimestamp && lhsHideStatus == rhsHideStatus
    case (.bridgeSubTx(let lhsIsFrom, let lhsTx), .bridgeSubTx(let rhsIsFrom, let rhsTx)):
      return lhsIsFrom == rhsIsFrom && lhsTx.tx == rhsTx.tx
    case (.stepSeparator, .stepSeparator):
      return true
    case (.bridgeFee(let lhsFee), .bridgeFee(let rhsFee)):
      return lhsFee == rhsFee
    case (.estimatedBridgeTime(let lhsTime), .estimatedBridgeTime(let rhsTime)):
      return lhsTime == rhsTime
    case (.multisendHeader(let lhsTotal), .multisendHeader(let rhsTotal)):
      return lhsTotal == rhsTotal
    case (.multisendTx(let lhsIndex, let lhsAddress, let lhsAmount), .multisendTx(let rhsIndex, let rhsAddress, let rhsAmount)):
      return lhsIndex == rhsIndex && lhsAddress == rhsAddress && lhsAmount == rhsAmount
    case (.application(let lhsWalletAddress, let lhsAppAddress), .application(let rhsWalletAddress, let rhsAppAddress)):
      return lhsWalletAddress == rhsWalletAddress && lhsAppAddress == rhsAppAddress
    case (.txHash(let lhsHash), .txHash(let rhsHash)):
      return lhsHash == rhsHash
    case (.transactionFee(let lhsFee), .transactionFee(let rhsFee)):
      return lhsFee == rhsFee
    default:
      return false
    }
  }
  
}
