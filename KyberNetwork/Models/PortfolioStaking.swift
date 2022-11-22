//
//  PortfolioStaking.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 13/10/2022.
//

import Foundation

// MARK: - PendingUnstakesResponse
struct PendingUnstakesResponse: Codable {
    let pendingUnstakes: [PendingUnstake]
}

// MARK: - PendingUnstake
struct PendingUnstake: Codable {
    let chainID: Int
    let address, symbol: String
    let logo: String
    let balance: String
    let decimals: Int
    let platform: Platform
    let extraData: StakingExtraData
    let priceUsd: Double

    enum CodingKeys: String, CodingKey {
        case chainID = "chainId"
        case address, symbol, logo, balance, decimals, platform, extraData, priceUsd
    }
}

// MARK: - ExtraData
struct StakingExtraData: Codable {
    let status, nftID: String?

    enum CodingKeys: String, CodingKey {
        case status
        case nftID = "nftId"
    }
}

// MARK: - Platform
struct Platform: Codable {
    let name: String
    let logo: String
    let type, desc: String
}

// MARK: - EarningBalancesResponse
struct EarningBalancesResponse: Codable {
    let earningBalances: [EarningBalance]
}

// MARK: - EarningBalance
struct EarningBalance: Codable {
    let chainID: Int
    let platform: Platform
    let stakingToken, toUnderlyingToken: IngToken
    let underlyingUsd, apy, ratio: Double

    enum CodingKeys: String, CodingKey {
        case chainID = "chainId"
        case platform, stakingToken, toUnderlyingToken, underlyingUsd, apy, ratio
    }
}

// MARK: - IngToken
struct IngToken: Codable {
    let address, symbol: String
    let logo: String
    let balance: String
    let decimals: Int
}

// MARK: - OptionDetailResponse
struct OptionDetailResponse: Codable {
    let earningTokens: [EarningToken]
}

// MARK: - EarningToken
struct EarningToken: Codable {
    let addressStr, address, symbol, name: String
    let decimals: Int
    let logo: String
    let tag: String
    let exchangeRate: Double
    let desc: String
}
