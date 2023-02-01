//
//  ChainType.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import KrystalWallets
import UIKit

public enum ChainType: Codable, CaseIterable {
    case all
    case eth
    case goerli
    case bsc
    case bscTestnet
    case polygon
    case polygonTestnet
    case avalanche
    case avalancheTestnet
    case cronos
    case fantom
    case arbitrum
    case aurora
    case solana
    case klaytn
    case optimism
    
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
        case unknownValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .all
        case 1:
            self = .eth
        case 2:
            self = .goerli
        case 3:
            self = .bsc
        case 4:
            self = .bscTestnet
        case 5:
            self = .polygon
        case 6:
            self = .polygonTestnet
        case 7:
            self = .avalanche
        case 8:
            self = .avalancheTestnet
        case 9:
            self = .cronos
        case 10:
            self = .fantom
        case 11:
            self = .arbitrum
        case 12:
            self = .aurora
        case 13:
            self = .solana
        case 14:
            self = .klaytn
        case 15:
            self = .optimism
        default:
            throw CodingError.unknownValue
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .all:
            try container.encode(0, forKey: .rawValue)
        case .eth:
            try container.encode(1, forKey: .rawValue)
        case .goerli:
            try container.encode(2, forKey: .rawValue)
        case .bsc:
            try container.encode(3, forKey: .rawValue)
        case .bscTestnet:
            try container.encode(4, forKey: .rawValue)
        case .polygon:
            try container.encode(5, forKey: .rawValue)
        case .polygonTestnet:
            try container.encode(6, forKey: .rawValue)
        case .avalanche:
            try container.encode(7, forKey: .rawValue)
        case .avalancheTestnet:
            try container.encode(8, forKey: .rawValue)
        case .cronos:
            try container.encode(9, forKey: .rawValue)
        case .fantom:
            try container.encode(10, forKey: .rawValue)
        case .arbitrum:
            try container.encode(11, forKey: .rawValue)
        case .aurora:
            try container.encode(12, forKey: .rawValue)
        case .solana:
            try container.encode(13, forKey: .rawValue)
        case .klaytn:
            try container.encode(14, forKey: .rawValue)
        case .optimism:
            try container.encode(15, forKey: .rawValue)
        }
    }
}

public extension ChainType {
    
    func isSupportedEIP1559() -> Bool {
        switch self {
        case .eth, .avalanche, .polygon:
            return true
        default:
            return false
        }
    }
    
    func customRPC() -> CustomRPC {
        switch self {
        case .eth:
            return AllChains.ethMainnetPRC
        case .goerli:
            return AllChains.goerliPRC
        case .bsc, .all:
            return AllChains.bscMainnetPRC
        case .bscTestnet:
            return AllChains.bscRoptenPRC
        case .polygon:
            return AllChains.polygonMainnetPRC
        case .polygonTestnet:
            return AllChains.polygonRoptenPRC
        case .avalanche:
            return AllChains.avalancheMainnetPRC
        case .avalancheTestnet:
            return AllChains.avalancheRoptenPRC
        case .cronos:
            return AllChains.cronosMainnetRPC
        case .fantom:
            return AllChains.fantomMainnetRPC
        case .arbitrum:
            return AllChains.arbitrumMainnetRPC
        case .aurora:
            return AllChains.auroraMainnetRPC
        case .solana:
            return AllChains.solana
        case .klaytn:
            return AllChains.klaytnMainnetRPC
        case .optimism:
            return AllChains.optimismMainnetRPC
        }
    }
    
    func apiChainPath() -> String {
        return self.customRPC().apiChainPath
    }
    
    func chainPath() -> String {
        return "/\(self.apiChainPath())"
    }
    
    func proxyAddress() -> String {
        return self.customRPC().proxyAddress.lowercased()
    }
    
    func getChainId() -> Int {
        switch self {
        case .all:
            return 0
        default:
            return self.customRPC().chainID
        }
    }
  
    func chainIcon() -> UIImage? {
        if self == .all {
          return UIImage(named: "chain_all_icon")
        }
        return UIImage(named: self.customRPC().chainIcon)
    }
    
    func chainName() -> String {
        if self == .all {
            return "All Networks"
        }
        return self.customRPC().name
    }
    
    var supportMultisend: Bool {
        switch self {
        case .solana:
            return false
        default:
            return true
        }
    }
    
    func isSupportSwap() -> Bool {
        switch self {
        case .solana:
            return false
        default:
            return true
        }
    }
    
    func isSupportedHistoryAPI() -> Bool {
        switch self {
        case .cronos:
            return false
        default:
            return true
        }
    }
  
  func quoteToken() -> String {
    return self.customRPC().quoteToken
  }
    
  func quoteTokenAddress() -> String {
    return self.customRPC().quoteTokenAddress
  }
  
  static func make(chainID: Int) -> ChainType? {
    return ChainType.getAllChain().first { $0.getChainId() == chainID }
  }
  
  static func getAllChain(includeAll: Bool = false) -> [ChainType] {
    var allChains = ChainType.allCases

//    if KNEnvironment.default == .production {
//      allChains = allChains.filter { $0 != .ropsten && $0 != .bscTestnet && $0 != .polygonTestnet && $0 != .avalancheTestnet }
//    }
//
//    let shouldShowAurora = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.auroraChainIntegration)
//    if !shouldShowAurora && KNGeneralProvider.shared.currentChain != .aurora {
//      allChains = allChains.filter { $0 != .aurora }
//    }
//
//    let shouldShowSolana = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.solanaChainIntegration)
//    if !shouldShowSolana && KNGeneralProvider.shared.currentChain != .solana {
//      allChains = allChains.filter { $0 != .solana }
//    }
//
//    let shouldShowKlaytn = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.klaytnChainIntegration)
//    if !shouldShowKlaytn && KNGeneralProvider.shared.currentChain != .klaytn {
//      allChains = allChains.filter { $0 != .klaytn }
//    }
//    if !includeAll {
//      allChains = allChains.filter { $0 != .all }
//    } else {
//      allChains.bringToFront(item: .all)
//    }
    return allChains
  }
    
    func isSupportedBridge() -> Bool {
        switch self {
        case .solana:
            return false
        default:
            return true
        }
    }
    var isEVM: Bool {
        switch self {
        case .solana:
            return false
        default:
            return true
        }
    }
}

public extension ChainType {
  
  var addressType: KAddressType {
    switch self {
    case .solana:
      return .solana
    default:
      return .evm
    }
  }
  
}
