//
//  PortfolioStaking.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 13/10/2022.
//

import Foundation

// MARK: - PortfolioStakingResponse
struct PortfolioStakingResponse: Codable {
    let portfolio: PortfolioStaking
    let timestamp: Int
}

// MARK: - Portfolio
struct PortfolioStaking: Codable {
    let balances: [StakingBalance]
    let earningBalances: [EarningBalance]
    let pendingUnstakes: [StakingBalance]?
}

// MARK: - Balance
struct StakingBalance: Codable {
    let chainID: Int?
    let address, symbol: String
    let logo: String
    let balance: String
    let decimals: Int
    let platform: Platform?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case chainID = "chainId"
        case address, symbol, logo, balance, decimals, platform, status
    }
}

// MARK: - Platform
struct Platform: Codable {
    let name: String
    let logo: String
    let type, desc: String
}

// MARK: - EarningBalance
struct EarningBalance: Codable {
    let chainID: Int
    let platform: Platform
    let stakingToken, toUnderlyingToken: StakingBalance
    let underlyingUsd, apy, ratio: Double

    enum CodingKeys: String, CodingKey {
        case chainID = "chainId"
        case platform, stakingToken, toUnderlyingToken, underlyingUsd, apy, ratio
    }
}

