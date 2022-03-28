//
//  ChainType.swift
//  KyberNetwork
//
//  Created by Com1 on 28/03/2022.
//

import Foundation
enum ChainType: Codable, CaseIterable {
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
      self = .eth
    case 1:
      self = .bsc
    case 2:
      self = .polygon
    case 3:
      self = .avalanche
    case 4:
      self = .cronos
    case 5:
      self = .fantom
    case 6:
      self = .arbitrum
    default:
      throw CodingError.unknownValue
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .eth:
      try container.encode(0, forKey: .rawValue)
    case .bsc:
      try container.encode(1, forKey: .rawValue)
    case .polygon:
      try container.encode(2, forKey: .rawValue)
    case .avalanche:
      try container.encode(3, forKey: .rawValue)
    case .cronos:
      try container.encode(4, forKey: .rawValue)
    case .fantom:
      try container.encode(5, forKey: .rawValue)
    case .arbitrum:
      try container.encode(6, forKey: .rawValue)
    }
  }

  static func make(chainID: Int) -> ChainType? {
    if KNEnvironment.default == .ropsten {
      if chainID == Constants.ethRoptenPRC.chainID {
        return .eth
      } else if chainID == Constants.bscRoptenPRC.chainID {
        return .bsc
      } else if chainID == Constants.polygonRoptenPRC.chainID {
        return .polygon
      } else if chainID == Constants.avalancheRoptenPRC.chainID {
        return .avalanche
      }
    } else {
      if chainID == Constants.ethMainnetPRC.chainID {
        return .eth
      } else if chainID == Constants.bscMainnetPRC.chainID {
        return .bsc
      } else if chainID == Constants.polygonMainnetPRC.chainID {
        return .polygon
      } else if chainID == Constants.avalancheMainnetPRC.chainID {
        return .avalanche
      }
    }
    return nil
  }

  func chainName() -> String {
    switch self {
    case .eth:
     return "Ethereum"
    case .bsc:
      return "Binance Smart Chain"
    case .polygon:
      return "Polygon"
    case .avalanche:
      return "Avalanche"
    case .fantom:
      return "Fantom"
    case .cronos:
      return "Cronos"
    case .arbitrum:
      return "Arbitrum"
    }
  }
  
  func chainFullName() -> String {
    switch self {
    case .eth:
     return "Ethereum"
    case .bsc:
      return "Binance Smart Chain(BSC)"
    case .polygon:
      return "Polygon(Matic)"
    case .avalanche:
      return "Avalanche"
    case .fantom:
      return "Fantom"
    case .cronos:
      return "Cronos"
    case .arbitrum:
      return "Arbitrum"
    }
  }

  func chainIcon() -> UIImage? {
    switch self {
    case .eth:
      return UIImage(named: "chain_eth_icon")
    case .bsc:
      return UIImage(named: "chain_bsc_icon")
    case .polygon:
      return UIImage(named: "chain_polygon_big_icon")
    case .avalanche:
      return UIImage(named: "chain_avax_icon")
    case .cronos:
      return UIImage(named: "chain_cronos_icon")
    case .fantom:
      return UIImage(named: "chain_fantom_icon")
    case .arbitrum:
      return UIImage(named: "chain_arbitrum_icon")
    }
  }

  func blockExploreName() -> String {
    return "Block Explorer"
  }

  func isSupportedHistoryAPI() -> Bool {
    switch self {
    case .cronos:
      return false
    default:
      return true
    }
  }

  case eth
  case bsc
  case polygon
  case avalanche
  case cronos
  case fantom
  case arbitrum
}
