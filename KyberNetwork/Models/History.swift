//
//  History.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 22/09/2021.
//

import Foundation
import BigInt

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
  var from: ExtraBridgeTransaction?
  var to: ExtraBridgeTransaction?
  var type: String?
  var error: String?
  var crosschainStatus: String?
}

struct ExtraBridgeTransaction: Codable {
  var address: String
  var amount: BigInt
  var chainId: String
  var chainName: String
  var decimals: Int
  var token: String
  var tx: String
  var txStatus: String
  
  enum CodingKeys: String, CodingKey {
    case address, token, amount, chainId, chainName, tx, txStatus, decimals
  }
  
  init(address: String, token: String, amount: BigInt, chainId: String, chainName: String, tx: String, txStatus: String, decimals: Int) {
    self.address = address
    self.token = token
    self.amount = amount
    self.chainId = chainId
    self.chainName = chainName
    self.tx = tx
    self.txStatus = txStatus
    self.decimals = decimals
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.address = try container.decode(String.self, forKey: .address)
    self.token = try container.decode(String.self, forKey: .token)
    self.amount = BigInt(try container.decode(String.self, forKey: .amount)) ?? BigInt(0)
    self.chainId = try container.decode(String.self, forKey: .chainId)
    self.chainName = try container.decode(String.self, forKey: .chainName)
    self.tx = try container.decode(String.self, forKey: .tx)
    self.txStatus = try container.decode(String.self, forKey: .txStatus)
    self.decimals = try container.decode(Int.self, forKey: .decimals)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(address, forKey: .address)
    try container.encode(token, forKey: .token)
    try container.encode("\(amount)", forKey: .amount)
    try container.encode(chainId, forKey: .chainId)
    try container.encode(chainName, forKey: .chainName)
    try container.encode(tx, forKey: .tx)
    try container.encode(txStatus, forKey: .txStatus)
    try container.encode(decimals, forKey: .decimals)
  }
  
  var isCompleted: Bool {
    return txStatus.lowercased() == "success" || txStatus.lowercased() == "failure" || txStatus.lowercased() == "failed"
  }
  
}
