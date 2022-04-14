//
//  ChainType.swift
//  KyberNetwork
//
//  Created by Com1 on 28/03/2022.
//

import Foundation
import UIKit

enum ChainType: Codable, CaseIterable {
  enum Key: CodingKey {
    case rawValue
  }

  enum CodingError: Error {
    case unknownValue
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let rawValue = try container.decode(Int.self, forKey: .rawValue)
    switch rawValue {
    case 0:
      self = .eth
    case 1:
      self = .bsc
    case 2:
      self = .polygon
    case 3:
      self = .avalanche
    case 4:
      self = .cronos
    case 5:
      self = .fantom
    case 6:
      self = .arbitrum
    case 7:
      self = .aurora
    default:
      throw CodingError.unknownValue
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .eth:
      try container.encode(0, forKey: .rawValue)
    case .bsc:
      try container.encode(1, forKey: .rawValue)
    case .polygon:
      try container.encode(2, forKey: .rawValue)
    case .avalanche:
      try container.encode(3, forKey: .rawValue)
    case .cronos:
      try container.encode(4, forKey: .rawValue)
    case .fantom:
      try container.encode(5, forKey: .rawValue)
    case .arbitrum:
      try container.encode(6, forKey: .rawValue)
    case .aurora:
      try container.encode(7, forKey: .rawValue)
    }
  }

  static func make(chainID: Int) -> ChainType? {
    return ChainType.getAllChain().first { $0.getChainId() == chainID }
  }
  
  static func getAllChain() -> [ChainType] {
    var allChains = ChainType.allCases
    let shouldShowAurora = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.auroraChainIntegration)
    if !shouldShowAurora && KNGeneralProvider.shared.currentChain != .aurora {
      allChains = allChains.filter { $0 != .aurora }
    }
    return allChains
  }

  func customRPC() -> CustomRPC {
    switch self {
    case .eth:
      if KNEnvironment.default == .ropsten {
        return AllChains.ethRoptenPRC
      } else if KNEnvironment.default == .staging {
        return AllChains.ethStaggingPRC
      }
      return AllChains.ethMainnetPRC
    case .bsc:
      if KNEnvironment.default == .ropsten {
        return AllChains.bscRoptenPRC
      }
      return AllChains.bscMainnetPRC
    case .polygon:
      if KNEnvironment.default == .ropsten {
        return AllChains.polygonRoptenPRC
      }
      return AllChains.polygonMainnetPRC
    case .avalanche:
      if KNEnvironment.default == .ropsten {
        return AllChains.avalancheRoptenPRC
      }
      return AllChains.avalancheMainnetPRC
    case .cronos:
        return AllChains.cronosMainnetRPC
    case .fantom:
        return AllChains.fantomMainnetRPC
    case .arbitrum:
        return AllChains.arbitrumMainnetRPC
    case .aurora:
      return AllChains.auroraMainnetRPC
    }
  }

  func isSupportedEIP1559() -> Bool {
    switch self {
    case .eth, .avalanche, .polygon:
      return true
    default:
      return false
    }
  }

  func apiChainPath() -> String {
    return self.customRPC().apiChainPath
  }

  func chainPath() -> String {
    return "/\(self.apiChainPath())"
  }

  func proxyAddress() -> String {
    return self.customRPC().proxyAddress.lowercased()
  }

  func getChainId() -> Int {
    return self.customRPC().chainID
  }

  func chainName() -> String {
    return self.self.customRPC().name
  }

  func chainIcon() -> UIImage? {
    return UIImage(named: self.customRPC().chainIcon)
  }

  func compoundSymbol() -> String {
    switch self {
    case .eth:
      return "COMP"
    case .bsc:
      return "XVS"
    case .polygon:
      return "COMP"
    default:
        return ""
    }
  }

  func compoundImageIcon() -> UIImage? {
    switch self {
    case .eth:
      return UIImage(named: "comp_icon")
    case .bsc:
      return UIImage(named: "venus_icon")
    case .polygon:
      return UIImage(named: "comp_icon")
    default:
      return UIImage(named: "") //TODO: wait for compound icon
    }
  }

  func tokenType() -> String {
    return self.customRPC().type
  }

  func quoteToken() -> String {
    return self.customRPC().quoteToken
  }

  func apiKey() -> String {
    switch self {
    case .eth:
      return KNSecret.etherscanAPIKey
    case .bsc:
      return KNSecret.bscscanAPIKey
    case .polygon:
      return KNSecret.polygonscanAPIKey
    default:
      return ""
    }
  }

  func lendingDistributionPlatform() -> String {
    switch self {
    case .eth:
      return "Compound"
    case .bsc:
      return "Venus"
    default:
      return ""
    }
  }

  func quoteTokenObject() -> TokenObject {
    let token = KNSupportedTokenStorage.shared.supportedToken.first { (token) -> Bool in
      return token.symbol == self.customRPC().quoteToken
    } ?? Token(name: self.customRPC().quoteToken, symbol: self.customRPC().quoteToken, address: self.customRPC().quoteTokenAddress, decimals: 18, logo: self.customRPC().quoteToken.lowercased())
    return token.toObject()
  }

  func otherTokenObject(toToken: TokenObject) -> TokenObject {
    if toToken.isQuoteToken {
      return self.defaultToSwapToken()
    }
    return self.quoteTokenObject()
  }

  func quoteTokenPrice() -> TokenPrice? {
    return KNTrackerRateStorage.shared.getPriceWithAddress(self.customRPC().quoteTokenAddress)
  }

  func getChainDBPath() -> String {
    switch self {
    case .arbitrum, .aurora:
      return "\(self.customRPC().chainID)" + "-" + KNEnvironment.default.displayName + "-"
    default:
      return self.customRPC().quoteToken.lowercased() + "-" + KNEnvironment.default.displayName + "-"
    }
  }

  func defaultToSwapToken() -> TokenObject {
    switch self {
    case .eth:
      return KNSupportedTokenStorage.shared.kncToken
    case .bsc:
        return KNSupportedTokenStorage.shared.busdToken
    case .polygon:
        return KNSupportedTokenStorage.shared.usdcToken
    case .avalanche:
        return KNSupportedTokenStorage.shared.usdceToken
    case .cronos:
        return KNSupportedTokenStorage.shared.usdcToken
    case .fantom:
        return KNSupportedTokenStorage.shared.usdcToken
    case .arbitrum:
        return KNSupportedTokenStorage.shared.usdcToken
    case .aurora:
        return KNSupportedTokenStorage.shared.usdcToken
    }
  }

  func recommendTags() -> [String] {
    switch self {
    case .eth:
      return ["ETH", "USDC", "USDT", "WBTC", "DAI", "UNI", "LINK", "AAVE"]
    case .bsc:
      return ["BNB", "BUSD", "CAKE", "USDT", "BTCB", "ETH", "USDC", "SAFEMOON"]
    default:
      return []
    }
  }

  func blockExploreName() -> String {
    return "Block Explorer"
  }

  func isSupportedHistoryAPI() -> Bool {
    switch self {
    case .cronos, .aurora:
      return false
    default:
      return true
    }
  }

  case eth
  case bsc
  case polygon
  case avalanche
  case cronos
  case fantom
  case arbitrum
  case aurora
}

enum CurrencyMode: Int {
  case usd = 0
  case eth
  case btc
  case quote

  func symbol() -> String {
    switch self {
    case .usd:
      return "$"
    case .btc:
      return "₿"
    case .eth:
      return "⧫"
    case .quote:
      return ""
    }
  }

  func suffixSymbol() -> String {
    switch self {
    case .quote:
      return " \(KNGeneralProvider.shared.currentChain.quoteToken())"
    default:
      return ""
    }
  }

  func toString() -> String {
    switch self {
    case .eth:
      return "eth"
    case .usd:
      return "usd"
    case .btc:
      return "btc"
    case .quote:
        return KNGeneralProvider.shared.currentChain.quoteToken().lowercased()
    }
  }

  func decimalNumber() -> Int {
    switch self {
    case .eth:
      return DecimalNumber.eth
    case .usd:
      return DecimalNumber.usd
    case .btc:
      return DecimalNumber.btc
    case .quote:
      return DecimalNumber.quote
    }
  }

  var isQuoteCurrency: Bool {
    return self == .quote
  }
}
