//
//  PortfolioSectionItem.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/07/2022.
//

import Foundation

enum PortfolioSectionItem {
  case asset(token: Token, price: Double)
  case lending(balance: LendingBalance)
  case lendingDist(balance: LendingDistributionBalance)
  case pool(lp: LPTokenModel)
  case nft(item: NFTItem)
  case market(token: TokenObject)
}
