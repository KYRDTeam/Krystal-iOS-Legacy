//
//  SolanaTransactionObject.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation

struct SolanaTransactionObject: Codable {
  var blockTime: Int
  var slot: Int
  var txHash: String
  var fee: Int
  var status: String
  var lamport: Int
  var signer: [String]
  var details: DetailsObject
  var parsedInstruction: [InstructionObject]
  
  struct DetailsObject: Codable {
    var recentBlockhash: String
    var solTransferTxs: [SolTransferTxObject]
    var tokensTransferTxs: [TokenTransferTxObject]
    var unknownTransferTxs: [UnknownTransferTxObject]
    var raydiumTxs: [RaydiumTxObject]
    var inputAccount: [InputAccountObject]
    
    init(_ details: SolanaTransaction.Details) {
      self.recentBlockhash = details.recentBlockhash
      self.solTransferTxs = details.solTransferTxs.map(SolanaTransactionObject.DetailsObject.SolTransferTxObject.init)
      self.tokensTransferTxs = details.tokensTransferTxs.map(SolanaTransactionObject.DetailsObject.TokenTransferTxObject.init)
      self.unknownTransferTxs = details.unknownTransferTxs.map(SolanaTransactionObject.DetailsObject.UnknownTransferTxObject.init)
      self.raydiumTxs = details.raydiumTxs.map(SolanaTransactionObject.DetailsObject.RaydiumTxObject.init)
      self.inputAccount = details.inputAccount.map(SolanaTransactionObject.DetailsObject.InputAccountObject.init)
    }
    
    struct InputAccountObject: Codable {
      var account: String
      var signer: Bool
      var writable: Bool
      var preBalance: Int
      var postBalance: Int
      
      init(_ inputAccount: SolanaTransaction.Details.InputAccount) {
        self.account = inputAccount.account
        self.signer = inputAccount.signer
        self.writable = inputAccount.writable
        self.preBalance = inputAccount.preBalance
        self.postBalance = inputAccount.postBalance
      }
    }
    
    struct SolTransferTxObject: Codable {
      var source: String
      var destination: String
      var amount: Double
      
      init(_ tx: SolanaTransaction.Details.SolTransferTx) {
        self.source = tx.source
        self.destination = tx.destination
        self.amount = tx.amount
      }
    }
    
    struct TokenTransferTxObject: Codable {
      var amount: Double
      var destination: String
      var destinationOwner: String
      var source: String
      var sourceOwner: String
      var token: TokenObject
      var type: String
      
      init(_ tx: SolanaTransaction.Details.TokenTransferTx) {
        self.amount = tx.amount
        self.destination = tx.destination
        self.destinationOwner = tx.destinationOwner
        self.source = tx.source
        self.sourceOwner = tx.sourceOwner
        self.token = TokenObject(tx.token)
        self.type = tx.type
      }

      struct TokenObject: Codable {
        var address: String
        var decimals: Int
        var icon: String
        var symbol: String
        
        init(_ token: SolanaTransaction.Details.TokenTransferTx.Token) {
          self.address = token.address
          self.decimals = token.decimals
          self.icon = token.icon
          self.symbol = token.symbol
        }
      }
    }
    
    struct UnknownTransferTxObject: Codable {
      var event: [EventObject]
      var programId: String
      
      init(_ tx: SolanaTransaction.Details.UnknownTransferTx) {
        self.event = tx.event.map(SolanaTransactionObject.DetailsObject.EventObject.init)
        self.programId = tx.programId
      }
    }
    
    struct RaydiumTxObject: Codable {
      var swap: SwapObject?
      
      init(_ tx: SolanaTransaction.Details.RaydiumTx) {
        self.swap = tx.swap.map { SwapObject($0) }
      }
      
      struct SwapObject: Codable {
        var coin: CoinObject
        var event: [EventObject]
        
        init(_ swap: SolanaTransaction.Details.RaydiumTx.Swap) {
          coin = CoinObject(swap.coin)
          event = swap.event.map { EventObject($0) }
        }
        
        struct CoinObject: Codable {
          var amount: Double
          var decimals: Int
          var symbol: String
          var tokenAddress: String
          
          init(_ coin: SolanaTransaction.Details.RaydiumTx.Swap.Coin) {
            amount = coin.amount
            decimals = coin.decimals
            symbol = coin.symbol
            tokenAddress = coin.tokenAddress
          }
        }
      }
      
    }
    
    struct EventObject: Codable {
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
      
      init(_ event: SolanaTransaction.Details.Event) {
        self.amount = event.amount
        self.decimals = event.decimals
        self.destination = event.destination
        self.destinationOwner = event.destinationOwner
        self.icon = event.icon
        self.source = event.source
        self.sourceOwner = event.sourceOwner
        self.symbol = event.symbol
        self.tokenAddress = event.tokenAddress
        self.type = event.type
      }
    }
  }
  
  struct InstructionObject: Codable {
    var programId: String
    var type: String
    
    init(_ instruction: SolanaTransaction.Instruction) {
      self.programId = instruction.programId
      self.type = instruction.type
    }
  }
  
  init(_ transaction: SolanaTransaction) {
    self.blockTime = transaction.blockTime
    self.slot = transaction.slot
    self.txHash = transaction.txHash
    self.fee = transaction.fee
    self.status = transaction.status
    self.lamport = transaction.lamport
    self.signer = transaction.signer
    self.details = DetailsObject(transaction.details)
    self.parsedInstruction = transaction.parsedInstruction.map(InstructionObject.init)
  }
  
}

extension SolanaTransactionObject {
  
  func toDomain() -> SolanaTransaction {
    return .init(blockTime: blockTime,
                 slot: slot,
                 txHash: txHash,
                 fee: fee,
                 status: status,
                 lamport: lamport,
                 signer: signer,
                 details: details.toDomain(),
                 parsedInstruction: parsedInstruction.map { $0.toDomain() }
    )
  }
  
}

extension SolanaTransactionObject.InstructionObject {
  
  func toDomain() -> SolanaTransaction.Instruction {
    return .init(programId: programId, type: type)
  }
  
}

extension SolanaTransactionObject.DetailsObject {
  
  func toDomain() -> SolanaTransaction.Details {
    return .init(recentBlockhash: recentBlockhash,
                 solTransferTxs: solTransferTxs.map { $0.toDomain() },
                 tokensTransferTxs: tokensTransferTxs.map { $0.toDomain() },
                 unknownTransferTxs: unknownTransferTxs.map { $0.toDomain() },
                 raydiumTxs: raydiumTxs.map { $0.toDomain() },
                 inputAccount: inputAccount.map { $0.toDomain() })
  }
  
}

extension SolanaTransactionObject.DetailsObject.InputAccountObject {
  
  func toDomain() -> SolanaTransaction.Details.InputAccount {
    return .init(account: account, signer: signer, writable: writable, preBalance: preBalance, postBalance: postBalance)
  }
  
}

extension SolanaTransactionObject.DetailsObject.SolTransferTxObject {
  
  func toDomain() -> SolanaTransaction.Details.SolTransferTx {
    return .init(source: source, destination: destination, amount: Double(amount))
  }
  
}

extension SolanaTransactionObject.DetailsObject.TokenTransferTxObject {
  
  func toDomain() -> SolanaTransaction.Details.TokenTransferTx {
    return .init(amount: Double(amount) ?? 0, destination: destination, destinationOwner: destinationOwner, source: source, sourceOwner: sourceOwner, token: token.toDomain(), type: type)
  }
  
}

extension SolanaTransactionObject.DetailsObject.TokenTransferTxObject.TokenObject {
  
  func toDomain() -> SolanaTransaction.Details.TokenTransferTx.Token {
    return .init(address: address, decimals: decimals, icon: icon, symbol: symbol)
  }
  
}

extension SolanaTransactionObject.DetailsObject.UnknownTransferTxObject {
  
  func toDomain() -> SolanaTransaction.Details.UnknownTransferTx {
    return .init(event: event.map { $0.toDomain() }, programId: programId)
  }
  
}

extension SolanaTransactionObject.DetailsObject.RaydiumTxObject {
  
  func toDomain() -> SolanaTransaction.Details.RaydiumTx {
    return .init(swap: swap?.toDomain())
  }
  
}

extension SolanaTransactionObject.DetailsObject.RaydiumTxObject.SwapObject {
  
  func toDomain() -> SolanaTransaction.Details.RaydiumTx.Swap {
    return .init(coin: coin.toDomain(), event: event.map { $0.toDomain() })
  }
  
}

extension SolanaTransactionObject.DetailsObject.RaydiumTxObject.SwapObject.CoinObject {
  
  func toDomain() -> SolanaTransaction.Details.RaydiumTx.Swap.Coin {
    return .init(amount: amount, decimals: decimals, symbol: symbol, tokenAddress: tokenAddress)
  }
  
}
      

extension SolanaTransactionObject.DetailsObject.EventObject {
  
  func toDomain() -> SolanaTransaction.Details.Event {
    return .init(amount: Double(amount) ?? 0, decimals: decimals, symbol: symbol, type: type)
  }
  
}

