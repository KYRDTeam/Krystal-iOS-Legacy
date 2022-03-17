//
//  PromoCodeStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 14/03/2022.
//

import Foundation

enum PromoCodeStatus: Codable {
  case pending
  case claimed
  case expired
}

struct PromoCodeItem: Codable {
  let title: String
  let expired: Double
  let description: String
  let logoURL: String
  let bannerURL: String
  let type: PromoCodeStatus
  
  
}

// MARK: - PromotionResponse
struct PromotionResponse: Codable {
    let codes: [PromoCode]
}

// MARK: - Code
struct PromoCode: Codable {
    let campaign: Campaign
    let code, reward, status: String
}

// MARK: - Campaign
struct Campaign: Codable {
    let title: String
    let expired: Int
    let campaignDescription, logoURL, bannerURL: String

    enum CodingKeys: String, CodingKey {
        case title, expired
        case campaignDescription = "description"
        case logoURL = "logoUrl"
        case bannerURL = "bannerUrl"
    }
}

extension PromoCode {
  func isExpired() -> Bool {
    let currentTS = Date().timeIntervalSince1970
    return currentTS > Double(self.campaign.expired)
  }
  
  func getStatus() -> PromoCodeStatus {
    if self.status == "claimed" {
      return .claimed
    } else {
      return self.isExpired() ? .expired : .pending
    }
  }
}

// MARK: - ClaimResponse
struct ClaimResponse: Codable {
    let message: String
    let success: Bool
}

// MARK: - ClaimErrorResponse
struct ClaimErrorResponse: Codable {
    let timestamp: Int
    let error: String
}
