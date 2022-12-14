//
//  Krytal.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import Foundation

// MARK: - ReferralOverviewData
struct ReferralOverviewData: Codable {
  let timestamp: Int?
  let codeStats: [String: Code]
  let rewardToken: Token
  let rewardAmount, nextRewardAmount, volForNextReward, totalVol, bonusVol, bonusRatio: Double
}

// MARK: - Code
struct Code: Codable {
    let totalRefer, vol, ratio: Double
}

// MARK: - ClaimHistoryResponse
struct ClaimHistoryResponse: Codable {
    let timestamp: Int
    let claims: [Claim]
    let total, offset, limit: Int
}

// MARK: - Claim
struct Claim: Codable {
    let amount: Double
    let fulfill: Bool
    let timestamp: Int
    let txHash: String
}

// MARK: - ReferralTiers
struct ReferralTiers: Codable {
  let timestamp: Int?
  let tiers: [Tier]
}

// MARK: - Tier
struct Tier: Codable {
  let level: Int
  let volume, reward: Double
}
