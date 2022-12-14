//
//  ChainType+.swift
//  BaseModule
//
//  Created by Tung Nguyen on 18/10/2022.
//

import Foundation
import BaseWallet
import UIKit

public extension ChainType {
  
  func squareIcon() -> UIImage {
    switch self {
    case .all:
      return .allNetworkSquare
    case .eth:
      return .chainEthSquare
    case .goerli:
      return .chainEthSquare
    case .bsc:
      return .chainBscSquare
    case .bscTestnet:
      return .chainBscSquare
    case .polygon:
      return .chainPolygonSquare
    case .polygonTestnet:
      return .chainPolygonSquare
    case .avalanche:
      return .chainAvaxSquare
    case .avalancheTestnet:
      return .chainAvaxSquare
    case .cronos:
      return .chainCronosSquare
    case .fantom:
      return .chainFantomSquare
    case .arbitrum:
      return .chainArbitrumSquare
    case .aurora:
      return .chainAuroraSquare
    case .solana:
      return .chainSolanaSquare
    case .klaytn:
      return .chainKlaytnSquare
    case .optimism:
      return .chainOptimismSquare
    }
  }
  
}
