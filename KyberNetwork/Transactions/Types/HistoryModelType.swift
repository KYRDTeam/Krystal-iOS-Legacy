//
//  HistoryModelType.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import UIKit

enum HistoryModelType: Codable {
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
      self = .swap
    case 1:
      self = .withdraw
    case 2:
      self = .transferETH
    case 3:
      self = .receiveETH
    case 4:
      self = .transferToken
    case 5:
      self = .receiveToken
    case 6:
      self = .allowance
    case 7:
      self = .earn
    case 8:
      self = .contractInteraction
    case 9:
      self = .selfTransfer
    case 10:
      self = .createNFT
    case 11:
      self = .transferNFT
    case 12:
      self = .receiveNFT
    case 13:
      self = .claimReward
    case 14:
      self = .multiSend
    case 15:
      self = .bridge
    default:
      throw CodingError.unknownValue
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .swap:
      try container.encode(0, forKey: .rawValue)
    case .withdraw:
      try container.encode(1, forKey: .rawValue)
    case .transferETH:
      try container.encode(2, forKey: .rawValue)
    case .receiveETH:
      try container.encode(3, forKey: .rawValue)
    case .transferToken:
      try container.encode(4, forKey: .rawValue)
    case .receiveToken:
      try container.encode(5, forKey: .rawValue)
    case .allowance:
      try container.encode(6, forKey: .rawValue)
    case .earn:
      try container.encode(7, forKey: .rawValue)
    case .contractInteraction:
      try container.encode(8, forKey: .rawValue)
    case .selfTransfer:
      try container.encode(9, forKey: .rawValue)
    case .createNFT:
      try container.encode(10, forKey: .rawValue)
    case .transferNFT:
      try container.encode(11, forKey: .rawValue)
    case .receiveNFT:
      try container.encode(12, forKey: .rawValue)
    case .claimReward:
      try container.encode(13, forKey: .rawValue)
    case .multiSend:
      try container.encode(14, forKey: .rawValue)
    case .bridge:
      try container.encode(15, forKey: .rawValue)
    }
  }

  case swap
  case withdraw
  case transferETH
  case receiveETH
  case transferToken
  case receiveToken
  case allowance
  case earn
  case contractInteraction
  case selfTransfer
  case createNFT
  case transferNFT
  case receiveNFT
  case claimReward
  case multiSend
  case bridge

  init(type: String) {
    switch type.lowercased() {
    case "swap":
      self = .swap
    case "withdraw":
      self = .withdraw
    case "transfereth":
      self = .transferETH
    case "receiveeth":
      self = .receiveETH
    case "transfertoken":
      self = .transferToken
    case "receivetoken":
      self = .receiveToken
    case "allowance":
      self = .allowance
    case "earn":
      self = .earn
    case "selftransfer":
      self = .selfTransfer
    case "createnft":
      self = .createNFT
    case "transfernft":
      self = .transferNFT
    case "receivenft":
      self = .receiveNFT
    case "claimreward":
      self = .claimReward
    case "multisend":
      self = .multiSend
    case "bridge":
      self = .bridge
    default:
      self = .contractInteraction
    }
  }
  
  static func typeFromInput(_ input: String) -> HistoryModelType {
    guard !input.isEmpty, input != "0x"  else {
      return .transferETH
    }

    let prefix = input.prefix(10)
    switch prefix {
    case "0x095ea7b3":
      return .allowance
    case "0x818e80b7", "0xdb006a75":
      return .withdraw
    case "0x30037de5", "0x9059232f", "0x852a12e3":
      return .earn
    case "0xa9059cbb":
      return .transferToken
    case "0xcf512b53", "0x12342114", "0xae591d54", "0x7a6c0dfe", "0x2db897d0":
      return .swap
    case "0x42842e0e", "0xf242432a":
      return .transferNFT
    case "0xd0def521", "0x731133e9":
      return .createNFT
    case "0x70ef85ea":
      return .claimReward
    default:
      return .contractInteraction
    }
  }
}

extension HistoryModelType {
  
  var displayString: String {
    switch self {
    case .swap:
      return "SWAP"
    case .withdraw:
      return "WITHDRAWAL"
    case .transferETH:
      return "TRANSFER"
    case .receiveETH:
      return "RECEIVED"
    case .transferToken:
      return "TRANSFER"
    case .receiveToken:
      return "RECEIVED"
    case .allowance:
      return "APPROVED"
    case .earn:
      return "SUPPLY"
    case .contractInteraction:
      return "CONTRACT EXECUTION"
    case .selfTransfer:
      return "SELF"
    case .createNFT:
      return "MINT"
    case .transferNFT:
      return "TRANSFER"
    case .receiveNFT:
      return "RECEIVED"
    case .claimReward:
      return "CLAIM REWARD"
    case .multiSend:
      return "MULTISEND"
    case .bridge:
      return "BRIDGE"
    }
  }
  
  var displayIcon: UIImage {
    switch self {
    case .swap:
      return UIImage()
    case .withdraw:
      return UIImage()
    case .transferETH:
      return Images.historyTransfer
    case .receiveETH:
      return Images.historyReceive
    case .transferToken:
      return Images.historyTransfer
    case .receiveToken:
      return Images.historyReceive
    case .allowance:
      return Images.historyApprove
    case .earn:
      return UIImage()
    case .contractInteraction:
      return Images.historyContractInteraction
    case .selfTransfer:
      return Images.historyTransfer
    case .createNFT:
      return Images.historyReceive
    case .transferNFT:
      return Images.historyTransfer
    case .receiveNFT:
      return Images.historyReceive
    case .claimReward:
      return Images.historyClaimReward
    case .multiSend:
      return Images.historyMultisend
    case .bridge:
      return Images.historyBridge
    }
  }
  
    func getTransactionType() -> UserService.TransactionType {
        switch self {
        case .swap:
            return .swap
        case .withdraw:
            return .claim
        case .transferETH:
            return .transfer
        case .receiveETH:
            return .transfer
        case .transferToken:
            return .transfer
        case .receiveToken:
            return .transfer
        case .allowance:
            return .undefine
        case .earn:
            return .earn
        case .contractInteraction:
            return .undefine
        case .selfTransfer:
            return .transfer
        case .createNFT:
            return .undefine
        case .transferNFT:
            return .nft_transfer
        case .receiveNFT:
            return .undefine
        case .claimReward:
            return .claim
        case .multiSend:
            return .multisend
        case .bridge:
            return .bridge
        }
    }
    
    
}
