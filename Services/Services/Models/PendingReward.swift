//
//  PendingReward.swift
//  Services
//
//  Created by Ta Minh Quan on 08/12/2022.
//

import Foundation

// MARK: - PendingRewardResponseElement
struct PendingRewardResponseElement: Codable {
    let earningRewards: [EarningReward]
    let platform: RewardPlatform
}

// MARK: - EarningReward
struct EarningReward: Codable {
    let chain: Chain
    let rewardTokens: [RewardToken]?
}

// MARK: - Chain
struct Chain: Codable {
    let id: Int
    let name: String
    let logo: String
}

// MARK: - RewardToken
struct RewardToken: Codable {
    let tokenInfo: TokenInfo
    let pendingReward: PendingReward
}

// MARK: - PendingReward
struct PendingReward: Codable {
    let balance: String
    let balancePriceUsd: Double
}

// MARK: - TokenInfo
struct TokenInfo: Codable {
    let address, name, symbol: String
    let logo: String
    let decimals: Int
}

// MARK: - Platform
struct RewardPlatform: Codable {
    let name: String
    let logo: String
    let platformDescription, earningType: String

    enum CodingKeys: String, CodingKey {
        case name, logo
        case platformDescription = "description"
        case earningType
    }
}

typealias PendingRewardResponse = [PendingRewardResponseElement]

