//
//  SolanaTransaction.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

struct SolanaTransactionListDTO: Decodable {
  var transactions: [SolanaTransactionDTO]
  
  enum CodingKeys: String, CodingKey {
    case transactions
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.transactions = try container.decodeIfPresent([SolanaTransactionDTO].self, forKey: .transactions) ?? []
  }
}

struct SolanaTransactionDTO: Decodable {
  var userAddress: String
  var blockTime: Int
  var slot: Int
  var txHash: String
  var fee: Int
  var status: String
  var lamport: Int
  var signer: [String]
  var details: DetailsDTO
  var parsedInstruction: [InstructionDTO]?
  
  struct DetailsDTO: Decodable {
    var recentBlockhash: String
    var solTransfers: [SolTransferTxDTO]?
    var tokenTransfers: [TokenTransferTxDTO]?
    var unknownTransfers: [UnknownTransferTxDTO]?
    var raydiumTransactions: [RaydiumTxDTO]?
    var inputAccount: [InputAccountDTO]?
    
    struct InputAccountDTO: Decodable {
      var account: String
      var signer: Bool
      var writable: Bool
      var preBalance: Int
      var postBalance: Int
    }
    
    struct SolTransferTxDTO: Decodable {
      var source: String
      var destination: String
      var amount: Double
    }
    
    struct TokenTransferTxDTO: Decodable {
      var amount: String
      var destination: String
      var destinationOwner: String?
      var source: String
      var sourceOwner: String?
      var token: TokenDTO
      var type: String?
      
      enum CodingKeys: String, CodingKey {
        case amount, destination, source, token, type
        case destinationOwner = "destination_owner"
        case sourceOwner = "source_owner"
      }

      struct TokenDTO: Decodable {
        var address: String
        var decimals: Int
        var icon: String
        var symbol: String
      }
    }
    
    struct UnknownTransferTxDTO: Decodable {
      var event: [EventDTO]
      var programId: String
    }
    
    struct RaydiumTxDTO: Decodable {
      var swap: SwapDTO?
      
      struct SwapDTO: Decodable {
        var event: [EventDTO]
        
        struct CoinDTO: Decodable {
          var amount: Double
          var decimals: Int
          var symbol: String
          var tokenAddress: String
        }
      }
      
    }
    
    struct EventDTO: Decodable {
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
  }
  
  struct InstructionDTO: Decodable {
    var programId: String
    var type: String
  }
  
}

extension SolanaTransactionDTO {
  
  func toDomain() -> SolanaTransaction {
    return .init(userAddress: userAddress,
                 blockTime: blockTime,
                 slot: slot,
                 txHash: txHash,
                 fee: fee,
                 status: status,
                 lamport: lamport,
                 signer: signer,
                 details: details.toDomain(),
                 parsedInstruction: parsedInstruction?.map { $0.toDomain() } ?? []
    )
  }
  
}

extension SolanaTransactionDTO.InstructionDTO {
  
  func toDomain() -> SolanaTransaction.Instruction {
    return .init(programId: programId, type: type)
  }
  
}

extension SolanaTransactionDTO.DetailsDTO {
  
  func toDomain() -> SolanaTransaction.Details {
    return .init(recentBlockhash: recentBlockhash,
                 solTransfers: solTransfers?.map { $0.toDomain() } ?? [],
                 tokenTransfers: tokenTransfers?.map { $0.toDomain() } ?? [],
                 unknownTransfers: unknownTransfers?.map { $0.toDomain() } ?? [],
                 raydiumTransactions: raydiumTransactions?.map { $0.toDomain() } ?? [],
                 inputAccount: inputAccount?.map { $0.toDomain() } ?? [])
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.InputAccountDTO {
  
  func toDomain() -> SolanaTransaction.Details.InputAccount {
    return .init(account: account, signer: signer, writable: writable, preBalance: preBalance, postBalance: postBalance)
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.SolTransferTxDTO {
  
  func toDomain() -> SolanaTransaction.Details.SolTransferTx {
    return .init(source: source, destination: destination, amount: Double(amount))
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.TokenTransferTxDTO {
  
  func toDomain() -> SolanaTransaction.Details.TokenTransferTx {
    return .init(amount: Double(amount) ?? 0, destination: destination, destinationOwner: destinationOwner ?? "", source: source, sourceOwner: sourceOwner ?? "", token: token.toDomain(), type: type)
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.TokenTransferTxDTO.TokenDTO {
  
  func toDomain() -> SolanaTransaction.Details.TokenTransferTx.Token {
    return .init(address: address, decimals: decimals, icon: icon, symbol: symbol)
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.UnknownTransferTxDTO {
  
  func toDomain() -> SolanaTransaction.Details.UnknownTransferTx {
    return .init(event: event.map { $0.toDomain() }, programId: programId)
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.RaydiumTxDTO {
  
  func toDomain() -> SolanaTransaction.Details.RaydiumTx {
    return .init(swap: swap?.toDomain())
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.RaydiumTxDTO.SwapDTO {
  
  func toDomain() -> SolanaTransaction.Details.RaydiumTx.Swap {
    return .init(event: event.map { $0.toDomain() })
  }
  
}

extension SolanaTransactionDTO.DetailsDTO.RaydiumTxDTO.SwapDTO.CoinDTO {
  
  func toDomain() -> SolanaTransaction.Details.RaydiumTx.Swap.Coin {
    return .init(amount: amount, decimals: decimals, symbol: symbol, tokenAddress: tokenAddress)
  }
  
}
      

extension SolanaTransactionDTO.DetailsDTO.EventDTO {
  
  func toDomain() -> SolanaTransaction.Details.Event {
    return .init(amount: Double(amount) ?? 0, decimals: decimals, destination: destination, destinationOwner: destinationOwner, source: source, sourceOwner: sourceOwner, symbol: symbol, type: type)
  }
  
}

