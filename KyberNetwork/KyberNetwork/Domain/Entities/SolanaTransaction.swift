//
//  SolanaTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/04/2022.
//

import Foundation

struct SolanaTransaction {
  var blockTime: Int
  var slot: Int
  var txHash: String
  var fee: Int
  var status: String
  var lamport: Int
  var signer: [String]
  var details: Details
  var parsedInstruction: [Instruction]
  
  struct Details {
    var recentBlockhash: String
    var solTransferTxs: [SolTransferTx]
    var tokensTransferTxs: [TokenTransferTx]
    var unknownTransferTxs: [UnknownTransferTx]
    
    struct SolTransferTx {
      var source: String
      var destination: String
      var amount: Double
    }
    
    struct TokenTransferTx {
      var amount: Double
      var destination: String
      var destinationOwner: String
      var source: String
      var sourceOwner: String
      var token: Token
      var type: String

      struct Token {
        var address: String
        var decimals: Int
        var icon: String
        var symbol: String
      }
    }
    
    struct UnknownTransferTx {
      var event: [Event]
      var programId: String
    }
    
    struct RaydiumTx {
      var swap: Swap
      
      struct Swap {
        var coin: Coin
        var event: [Event]
        
        struct Coin {
          var amount: Double
          var decimals: Int
          var symbol: String
          var tokenAddress: String
        }
      }
      
    }
    
    struct Event {
      var amount: Double
      var decimals: Int
      var destination: String?
      var destinationOwner: String?
      var icon: String?
      var source: String?
      var sourceOwner: String?
      var symbol: String
      var tokenAddress: String?
      var type: String
    }
  }
  
  struct Instruction {
    var programId: String
    var type: String
  }
  
}
