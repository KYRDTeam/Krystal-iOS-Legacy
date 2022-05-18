//
//  HistoryTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

struct HistoryTransaction: Codable {
  let type: HistoryModelType
  let timestamp: String
  let transacton: [EtherscanTransaction]
  let internalTransactions: [EtherscanInternalTransaction]
  let tokenTransactions: [EtherscanTokenTransaction]
  let nftTransaction: [NFTTransaction]
  let wallet: String

  var date: Date {
    return Date(timeIntervalSince1970: Double(self.timestamp) ?? 0)
  }
  
  var hash: String {
    if let tx = transacton.first {
      return tx.hash
    } else if let internalTx = self.internalTransactions.first {
      return internalTx.hash
    } else if let tokenTx = self.tokenTransactions.first {
      return tokenTx.hash
    }
    return ""
  }
}
