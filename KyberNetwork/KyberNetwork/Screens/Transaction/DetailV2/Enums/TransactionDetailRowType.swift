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
