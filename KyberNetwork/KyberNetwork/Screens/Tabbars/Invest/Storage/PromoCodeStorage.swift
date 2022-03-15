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
