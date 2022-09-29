//
//  RedeemStatus.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 20/09/2022.
//

import Foundation

enum RedeemPromotionStatus {
  case normal
  case processing
  case success
  case failure(message: String)
}
