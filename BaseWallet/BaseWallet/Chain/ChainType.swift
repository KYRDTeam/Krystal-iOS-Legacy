//
//  ChainType.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation

public enum ChainType: Codable {
    case all
    case eth
    case ropsten
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
            self = .ropsten
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
        case .ropsten:
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
        }
    }
}
