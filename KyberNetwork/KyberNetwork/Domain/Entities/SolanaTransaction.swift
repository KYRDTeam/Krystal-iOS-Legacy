//
//  SolanaTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/04/2022.
//

import Foundation

struct SolanaTransaction {
  var userAddress: String
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
    var solTransfers: [SolTransferTx]
    var tokenTransfers: [TokenTransferTx]
    var unknownTransfers: [UnknownTransferTx]
    var raydiumTransactions: [RaydiumTx]
    var inputAccount: [InputAccount]
    
    struct InputAccount {
      var account: String
      var signer: Bool
      var writable: Bool
      var preBalance: Int
      var postBalance: Int
    }
    
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
      var type: String?

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
      var swap: Swap?
      
      struct Swap {
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

extension SolanaTransaction {
  
  enum SolanaTransactionType {
    case swap(data: SwapData)
    case transfer(data: TransferData)
    case other(programId: String)
  }
  
  struct TransferData {
    var symbol: String
    var decimals: Int
    var amount: Double
    var sourceAddress: String
    var destinationAddress: String
  }
  
  struct SwapData {
    var sourceSymbol: String
    var sourceAmount: Double
    var sourceDecimals: Int
    var destinationSymbol: String
    var destinationAmount: Double
    var destinationDecimals: Int
    var programId: String
  }
  
  var type: SolanaTransactionType {
    if swapEvents.count >= 2 {
      let tx0 = swapEvents.first!
      let tx1 = swapEvents.last!
      let data = SwapData(sourceSymbol: tx0.symbol,
                          sourceAmount: tx0.amount,
                          sourceDecimals: tx0.decimals,
                          destinationSymbol: tx1.symbol,
                          destinationAmount: tx1.amount,
                          destinationDecimals: tx1.decimals,
                          programId: details.inputAccount.last?.account ?? "")
      return .swap(data: data)
    } else if details.tokenTransfers.isNotEmpty {
      let tx = details.tokenTransfers[0]
      let data = TransferData(symbol: tx.token.symbol,
                              decimals: tx.token.decimals,
                              amount: tx.amount,
                              sourceAddress: tx.sourceOwner,
                              destinationAddress: tx.destinationOwner)
      return .transfer(data: data)
    } else if details.solTransfers.isNotEmpty {
      let tx = details.solTransfers[0]
      let data = TransferData(symbol: AllChains.solana.symbol,
                              decimals: 9,
                              amount: tx.amount,
                              sourceAddress: tx.source,
                              destinationAddress: tx.destination)
      return .transfer(data: data)
    } else if details.unknownTransfers.isNotEmpty, let tx = details.unknownTransfers[0].event.first {
      let data = TransferData(symbol: tx.symbol,
                              decimals: tx.decimals,
                              amount: tx.amount,
                              sourceAddress: tx.source ?? "",
                              destinationAddress: tx.destination ?? "")
      return .transfer(data: data)
    } else {
      return .other(programId: details.inputAccount.last?.account ?? "")
    }
  }
  
  var swapEvents: [Details.Event] {
    let unknownTxEvents = details.unknownTransfers.flatMap(\.event)
    if unknownTxEvents.count >= 2 {
      return unknownTxEvents
    } else {
      let raydiumTxEvents = details.raydiumTransactions
        .compactMap(\.swap)
        .filter { !$0.event.contains { event in event.symbol.isEmpty } }
        .flatMap { $0.event }
      return raydiumTxEvents
    }
  }
  
  var isTransferToOther: Bool {
    switch type {
    case .transfer(let data):
      return data.sourceAddress == userAddress
    default:
      return false
    }
  }
  
}
