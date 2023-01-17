//
//  PendingReward.swift
//  Services
//
//  Created by Ta Minh Quan on 08/12/2022.
//

import Foundation

// MARK: - PendingRewardResponseElement
public struct PendingRewardResponseElement: Codable {
    public let earningRewards: [EarningReward]
    public let platform: RewardPlatform
}

// MARK: - EarningReward
public struct EarningReward: Codable {
    public let chain: Chain
    public let rewardTokens: [RewardToken]?
}

// MARK: - Chain
public struct Chain: Codable {
    public let id: Int
    public let name: String
    public let logo: String
}

// MARK: - RewardToken
public struct RewardToken: Codable {
    public let tokenInfo: TokenInfo
    public let pendingReward: PendingReward
}

// MARK: - PendingReward
public struct PendingReward: Codable {
    public let balance: String
    public let balancePriceUsd: Double
}

// MARK: - TokenInfo
public struct TokenInfo: Codable {
    public let address, name, symbol: String
    public let logo: String
    public let decimals: Int
    public let tag: String?
}

// MARK: - Platform
public struct RewardPlatform: Codable {
    public let name: String
    public let logo: String
    public let platformDescription, earningType: String

    enum CodingKeys: String, CodingKey {
        case name, logo
        case platformDescription = "description"
        case earningType
    }
    
    public func toEarnPlatform() -> EarnPlatform {
        let json: [String: Any] = [
            "name": name,
            "logo": logo,
            "type": earningType
        ]
        
        return EarnPlatform(json: json)
    }
}

public typealias PendingRewardResponse = [PendingRewardResponseElement]

