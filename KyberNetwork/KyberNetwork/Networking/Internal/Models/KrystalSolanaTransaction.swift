//
//  SolanaTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

struct KrystalSolanaTransactionListResponse: Decodable {
  var transactions: [KrystalSolanaTransaction]
}

struct KrystalSolanaTransaction: Decodable {
  var blockTime: Int
  var slot: Int
  var txHash: String
  var fee: Int
  var status: String
  var lamport: Int
  var signer: [String]
  var details: Details
  var parsedInstruction: [Instruction]
  
  struct Details: Decodable {
    var recentBlockhash: String
    var solTransferTxs: [SolTransferTx]
    var tokensTransferTxs: [TokenTransferTx]
    var unknownTransferTxs: [UnknownTransferTx]
    
    enum CodingKeys: String, CodingKey {
      case recentBlockhash
      case solTransferTxs = "sol_transfer_txs"
      case tokensTransferTxs = "tokens_transfer_txs"
      case unknownTransferTxs = "unknown_transfer_txs"
    }
  }
  
  struct Instruction: Decodable {
    var programId: String
    var type: String
  }
  
  struct SolTransferTx: Decodable {
    var source: String
    var destination: String
    var amount: Double
  }
      
  struct Token: Decodable {
    var address: String
    var decimals: Int
    var icon: String
    var symbol: String
  }
  
  struct TokenTransferTx: Decodable {
    var amount: String
    var destination: String
    var destinationOwner: String
    var source: String
    var sourceOwner: String
    var token: Token
    var type: String
    
    enum CodingKeys: String, CodingKey {
      case amount, destination, source, token, type
      case destinationOwner = "destination_owner"
      case sourceOwner = "source_owner"
    }
  }
  
  struct Event: Decodable {
    var amount: String
    var decimals: Int
    var destination: String?
    var destinationOwner: String?
    var icon: String?
    var source: String?
    var sourceOwner: String?
    var symbol: String
    var tokenAddress: String?
    var type: String
    
    enum CodingKeys: String, CodingKey {
      case amount, decimals, destination, destinationOwner, icon, source, sourceOwner, symbol, tokenAddress, type
    }
    
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      if let amount = try? container.decode(String.self, forKey: .amount) {
        self.amount = amount
      } else if let doubleAmount = try? container.decode(Int.self, forKey: .amount) {
        self.amount = String(doubleAmount)
      } else {
        self.amount = "0"
      }
      self.decimals = try container.decode(Int.self, forKey: .decimals)
      self.destination = try container.decodeIfPresent(String.self, forKey: .destination)
      self.destinationOwner = try container.decodeIfPresent(String.self, forKey: .destinationOwner)
      self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
      self.source = try container.decodeIfPresent(String.self, forKey: .source)
      self.sourceOwner = try container.decodeIfPresent(String.self, forKey: .sourceOwner)
      self.symbol = try container.decodeIfPresent(String.self, forKey: .symbol) ?? ""
      self.tokenAddress = try container.decodeIfPresent(String.self, forKey: .tokenAddress)
      self.type = try container.decode(String.self, forKey: .type)
    }
    
  }
  
  struct UnknownTransferTx: Decodable {
    var event: [Event]
    var programId: String
  }
  
}

