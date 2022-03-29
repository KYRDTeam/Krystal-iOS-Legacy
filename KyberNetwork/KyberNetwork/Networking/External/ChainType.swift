//
//  ChainType.swift
//  KyberNetwork
//
//  Created by Com1 on 28/03/2022.
//

import Foundation
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
    }
  }

  static func make(chainID: Int) -> ChainType? {
    if KNEnvironment.default == .ropsten {
      if chainID == Constants.ethRoptenPRC.chainID {
        return .eth
      } else if chainID == Constants.bscRoptenPRC.chainID {
        return .bsc
      } else if chainID == Constants.polygonRoptenPRC.chainID {
        return .polygon
      } else if chainID == Constants.avalancheRoptenPRC.chainID {
        return .avalanche
      }
    } else {
      if chainID == Constants.ethMainnetPRC.chainID {
        return .eth
      } else if chainID == Constants.bscMainnetPRC.chainID {
        return .bsc
      } else if chainID == Constants.polygonMainnetPRC.chainID {
        return .polygon
      } else if chainID == Constants.avalancheMainnetPRC.chainID {
        return .avalanche
      }
    }
    return nil
  }

  func customRPC() -> CustomRPC {
    switch self {
    case .eth:
      return KNEnvironment.default.ethRPC
    case .bsc:
      return KNEnvironment.default.bscRPC
    case .polygon:
      return KNEnvironment.default.maticRPC
    case .avalanche:
      return KNEnvironment.default.avalancheRPC
    case .cronos:
      return KNEnvironment.default.cronosRPC
    case .fantom:
      return KNEnvironment.default.fantomRPC
    case .arbitrum:
      return KNEnvironment.default.arbitrumRPC
    }
  }

  func quoteCurrency() -> CurrencyMode {
    switch self {
    case .eth:
      return .eth
    case .bsc:
      return .bnb
    case .polygon:
      return .matic
    case .avalanche:
      return .avax
    case .cronos:
      return .cro
    case .fantom:
      return .ftm
    case .arbitrum:
      return .eth
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
  
  func currentChainPathName() -> String {
    switch self {
    case .eth:
      if KNEnvironment.default == .ropsten {
        return "ropsten"
      }
      return "ethereum"
    case .bsc:
      if KNEnvironment.default == .ropsten {
        return "bsctestnet"
      }
      return "bsc"
    case .polygon:
      if KNEnvironment.default == .ropsten {
        return "mumbai"
      }
      return "polygon"
    case .avalanche:
      if KNEnvironment.default == .ropsten {
        return "fuji"
      }
      return "avalanche"
    case .cronos:
      return "cronos"
    case .fantom:
      return "fantom"
    case .arbitrum:
      return "arbitrum"
    }
  }

  func chainPath() -> String {
    return "/\(self.currentChainPathName())"
  }

  func proxyAddress() -> String {
    switch self {
    case .eth:
        return KNEnvironment.default == .ropsten ? Constants.ethRoptenPRC.proxyAddress.lowercased() : Constants.ethMainnetPRC.proxyAddress.lowercased()
    case .bsc:
      return KNEnvironment.default == .ropsten ? Constants.bscRoptenPRC.proxyAddress.lowercased() : Constants.bscMainnetPRC.proxyAddress.lowercased()
    case .polygon:
      return KNEnvironment.default == .ropsten ? Constants.polygonRoptenPRC.proxyAddress.lowercased() : Constants.polygonMainnetPRC.proxyAddress.lowercased()
    case .avalanche:
      return KNEnvironment.default == .ropsten ? Constants.avalancheRoptenPRC.proxyAddress.lowercased() : Constants.avalancheMainnetPRC.proxyAddress.lowercased()
    case .cronos:
      return Constants.cronosMainnetRPC.proxyAddress.lowercased()
    case .fantom:
      return Constants.fantomMainnetRPC.proxyAddress.lowercased()
    case .arbitrum:
      return Constants.arbitrumMainnetRPC.proxyAddress.lowercased()
    }
  }

  func chainName() -> String {
    switch self {
    case .eth:
     return "Ethereum"
    case .bsc:
      return "Binance Smart Chain"
    case .polygon:
      return "Polygon"
    case .avalanche:
      return "Avalanche"
    case .fantom:
      return "Fantom"
    case .cronos:
      return "Cronos"
    case .arbitrum:
      return "Arbitrum"
    }
  }

  func chainFullName() -> String {
    switch self {
    case .eth:
     return "Ethereum"
    case .bsc:
      return "Binance Smart Chain(BSC)"
    case .polygon:
      return "Polygon(Matic)"
    case .avalanche:
      return "Avalanche"
    case .fantom:
      return "Fantom"
    case .cronos:
      return "Cronos"
    case .arbitrum:
      return "Arbitrum"
    }
  }

  func chainIcon() -> UIImage? {
    switch self {
    case .eth:
      return UIImage(named: "chain_eth_icon")
    case .bsc:
      return UIImage(named: "chain_bsc_icon")
    case .polygon:
      return UIImage(named: "chain_polygon_big_icon")
    case .avalanche:
      return UIImage(named: "chain_avax_icon")
    case .cronos:
      return UIImage(named: "chain_cronos_icon")
    case .fantom:
      return UIImage(named: "chain_fantom_icon")
    case .arbitrum:
      return UIImage(named: "chain_arbitrum_icon")
    }
  }

  func compoundSymbol() -> String {
    switch self {
    case .eth:
      return "COMP"
    case .bsc:
      return "XVS"
    case .polygon:
      return "COMP"
    case .avalanche:
      return "" //TODO: wait for compound symbol
    case .cronos:
      return ""
    case .fantom:
      return ""
    case .arbitrum:
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
    case .avalanche:
      return UIImage(named: "") //TODO: wait for compound icon
    case .cronos:
      return UIImage(named: "")
    case .fantom:
      return UIImage(named: "")
    case .arbitrum:
      return UIImage(named: "")
    }
  }

  func tokenType() -> String {
    switch self {
    case .eth:
      return "ERC20"
    case .bsc:
      return "BEP20"
    case .polygon:
      return "ERC20"
    case .avalanche:
      return "ARC20"
    case .cronos:
      return "CRC20"
    case .fantom:
      return "ERC20"
    case .arbitrum:
      return "ERC20"
    }
  }

  func quoteToken() -> String {
    switch self {
    case .eth:
      return "ETH"
    case .bsc:
      return "BNB"
    case .polygon:
      return "MATIC"
    case .avalanche:
      return "AVAX"
    case .cronos:
      return "CRO"
    case .fantom:
      return "FTM"
    case .arbitrum:
      return "ETH"
    }
  }

  func apiKey() -> String {
    switch self {
    case .eth:
      return KNSecret.etherscanAPIKey
    case .bsc:
      return KNSecret.bscscanAPIKey
    case .polygon:
      return KNSecret.polygonscanAPIKey
    case .avalanche:
      return "" //TODO: wait for avalance api key
    case .cronos:
      return ""
    case .fantom:
      return ""
    case .arbitrum:
      return ""
    }
  }

  func lendingDistributionPlatform() -> String {
    switch self {
    case .eth:
      return "Compound"
    case .bsc:
      return "Venus"
    case .polygon:
      return ""
    case .avalanche:
      return ""
    case .cronos:
      return ""
    case .fantom:
      return ""
    case .arbitrum:
      return ""
    }
  }

  func quoteTokenObject() -> TokenObject {
    switch self {
    case .eth:
      return KNSupportedTokenStorage.shared.ethToken
    case .bsc:
      return KNSupportedTokenStorage.shared.bnbToken
    case .polygon:
      return KNSupportedTokenStorage.shared.maticToken
    case .avalanche:
      return KNSupportedTokenStorage.shared.avaxToken
    case .cronos:
      return KNSupportedTokenStorage.shared.cronosToken
    case .fantom:
      return KNSupportedTokenStorage.shared.fantomToken
    case .arbitrum:
      return KNSupportedTokenStorage.shared.ethToken
    }
  }

  func otherTokenObject(toToken: TokenObject) -> TokenObject {
    if toToken.isQuoteToken {
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
      }
    }
    return self.quoteTokenObject()
  }

  func quoteTokenPrice() -> TokenPrice? {
    switch self {
    case .eth:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.ethAddress)
    case .bsc:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.bnbAddress)
    case .polygon:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.maticAddress)
    case .avalanche:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.avaxAddress)
    case .cronos:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.cronosAddress)
    case .fantom:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.fantomAddress)
    case .arbitrum:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.arbitrumAddress)
    }
  }

  func priceAlertMessage() -> String {
    switch self {
    case .eth:
      return "There.is.a.difference.between.the.estimated.price".toBeLocalised()
    case .bsc:
      return "There.is.a.difference.between.the.estimated.price.bsc".toBeLocalised()
    case .polygon:
      return "There.is.a.difference.between.the.estimated.price.matic".toBeLocalised()
    case .avalanche:
      return "There.is.a.difference.between.the.estimated.price.avalanche".toBeLocalised()
    case .cronos:
      return "There.is.a.difference.between.the.estimated.price.cronos".toBeLocalised()
    case .fantom:
      return "There.is.a.difference.between.the.estimated.price.fantom".toBeLocalised()
    case .arbitrum:
      return "There.is.a.difference.between.the.estimated.price.arbitrum".toBeLocalised()
    }
  }

  func getChainDBPath() -> String {
    switch self {
    case .eth:
      return "eth" + "-" + KNEnvironment.default.displayName + "-"
    case .bsc:
      return "bnb" + "-" + KNEnvironment.default.displayName + "-"
    case .polygon:
      return "matic" + "-" + KNEnvironment.default.displayName + "-"
    case .avalanche:
      return "avax" + "-" + KNEnvironment.default.displayName + "-"
    case .cronos:
      return "cro" + "-" + KNEnvironment.default.displayName + "-"
    case .fantom:
      return "ftm" + "-" + KNEnvironment.default.displayName + "-"
    case .arbitrum:
      return "aeth" + "-" + KNEnvironment.default.displayName + "-"
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
    case .cronos:
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
}
