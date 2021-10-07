//
//  History.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 22/09/2021.
//

import Foundation

// MARK: - HistoryResponse
struct HistoryResponse: Codable {
  let timestamp: Int
  let transactions: [KrystalHistoryTransaction]
}

// MARK: - Transaction
struct KrystalHistoryTransaction: Codable, Equatable {
  let hash: String
  let blockNumber, timestamp: Int
  let from, to, status, value: String
  let valueQuote: Double
  let gasLimit, gasUsed: Int
  let gasPrice: String
  let gasPriceQuote: Double
  let gasCost: String
  let gasCostQuote: Double
  let type: String
  let nonce: Int
  let extraData: ExtraData?

  static func == (lhs: KrystalHistoryTransaction, rhs: KrystalHistoryTransaction) -> Bool {
    return lhs.hash == rhs.hash && lhs.blockNumber == rhs.blockNumber && lhs.timestamp == rhs.timestamp && lhs.from == rhs.from && lhs.to == rhs.to && lhs.status == rhs.status && lhs.value == rhs.value && lhs.type == rhs.type && lhs.nonce == rhs.nonce
  }
  
  var date: Date {
    return Date(timeIntervalSince1970: Double(self.timestamp))
  }
  
  var isSwapTokenType: Bool {
    return self.type == "Swap" || self.type == "Supply" || self.type == "Withdraw"
  }
}

// MARK: - ExtraData
struct ExtraData: Codable {
  let receiveToken: Token?
  let receiveValue, owner, spender: String?
  let token: Token?
  let tokenAddress, tokenName, value: String?
  let sendToken: Token?
  let sendValue: String?
}
