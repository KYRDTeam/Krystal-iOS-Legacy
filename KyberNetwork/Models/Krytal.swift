//
//  Krytal.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import Foundation

// MARK: - ReferralOverviewResponse
struct ReferralOverviewResponse: Codable {
    let timestamp: Int
    let overview: Overview
}

// MARK: - Overview
struct Overview: Codable {
    let claimablePoint, cashbackEscrowed, cashbackPoint: Double
    let codes: [String: Code]
}

// MARK: - Code
struct Code: Codable {
    let totalRefer, totalEscrowed, totalEarned, ratio: Double
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
