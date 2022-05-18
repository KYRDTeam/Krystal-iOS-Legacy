//
//  TransactionHistory.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/8/21.
//

import Foundation
import BigInt
import TrustCore
import TrustKeystore

struct TransactionResponse: Codable {
    let timestamp: Int?
    let error: String?
    let txObject: TxObject
}

enum InternalTransactionState: Codable {
  enum Key: CodingKey {
    case rawValue
  }
  
  enum CodingError: Error {
    case unknownValue
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let rawValue = try container.decode(Int.self, forKey: .rawValue)
    switch rawValue {
    case 0:
      self = .pending
    case 1:
      self = .speedup
    case 2:
      self = .cancel
    case 3:
      self = .done
    case 4:
      self = .drop
    case 5:
      self = .error
    default:
      throw CodingError.unknownValue
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .pending:
      try container.encode(0, forKey: .rawValue)
    case .speedup:
      try container.encode(1, forKey: .rawValue)
    case .cancel:
      try container.encode(2, forKey: .rawValue)
    case .done:
      try container.encode(3, forKey: .rawValue)
    case .drop:
      try container.encode(4, forKey: .rawValue)
    case .error:
      try container.encode(5, forKey: .rawValue)
    }
  }
  
  case pending
  case speedup
  case cancel
  case done
  case drop
  case error
}

struct InternalListResponse: Codable {
    let status, message: String
    let result: [EtherscanInternalTransaction]
}

struct EtherscanInternalTransaction: Codable, Equatable {
  static func == (lhs: EtherscanInternalTransaction, rhs: EtherscanInternalTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
    let blockNumber, timeStamp, hash, from: String
    let to, value, contractAddress, input: String
    let type, gas, gasUsed, traceID: String
    let isError, errCode: String

    enum CodingKeys: String, CodingKey {
        case blockNumber, timeStamp, hash, from, to, value, contractAddress, input, type, gas, gasUsed
        case traceID = "traceId"
        case isError, errCode
    }
}

struct TokenTransactionListResponse: Codable {
    let status, message: String
    let result: [EtherscanTokenTransaction]
}

struct EtherscanTokenTransaction: Codable, Equatable {
  static func == (lhs: EtherscanTokenTransaction, rhs: EtherscanTokenTransaction) -> Bool {
    return lhs.blockNumber == rhs.blockNumber
      && lhs.timeStamp == rhs.timeStamp
      && lhs.hash == rhs.hash
      && lhs.nonce == rhs.nonce
      && lhs.blockHash == rhs.blockHash
      && lhs.from == rhs.from
      && lhs.contractAddress == rhs.contractAddress
      && lhs.to == rhs.to
      && lhs.value == rhs.value
  }
  
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, from, contractAddress, to: String
    let value, tokenName, tokenSymbol, tokenDecimal: String
    let transactionIndex, gas, gasPrice, gasUsed: String
    let cumulativeGasUsed, input, confirmations: String
}

struct TransactionsListResponse: Codable {
    let status, message: String
    let result: [EtherscanTransaction]
}

struct EtherscanTransaction: Codable, Equatable {
  static func == (lhs: EtherscanTransaction, rhs: EtherscanTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
  
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, transactionIndex, from, to: String
    let value, gas, gasPrice, isError: String
    let txreceiptStatus, input, contractAddress, cumulativeGasUsed: String
    let gasUsed, confirmations: String

    enum CodingKeys: String, CodingKey {
        case blockNumber, timeStamp, hash, nonce, blockHash, transactionIndex, from, to, value, gas, gasPrice, isError
        case txreceiptStatus = "txreceipt_status"
        case input, contractAddress, cumulativeGasUsed, gasUsed, confirmations
    }
}

// MARK: - NFTHistoryResponse
struct NFTHistoryResponse: Codable {
    let status: String
    let result: [NFTTransaction]
}

// MARK: - Result
struct NFTTransaction: Codable, Equatable {
    let blockNumber, timeStamp, hash, nonce: String
    let blockHash, from, contractAddress, to: String
    let tokenID, tokenName, tokenSymbol, tokenDecimal: String
    let transactionIndex, gas, gasPrice, gasUsed: String
    let cumulativeGasUsed, input, confirmations: String
  
  static func == (lhs: NFTTransaction, rhs: NFTTransaction) -> Bool {
    return lhs.hash == rhs.hash
  }
}
