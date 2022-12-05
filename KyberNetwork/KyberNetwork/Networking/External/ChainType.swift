//
//  ChainType.swift
//  KyberNetwork
//
//  Created by Com1 on 28/03/2022.
//

import Foundation
import UIKit
import BaseWallet

typealias ChainType = BaseWallet.ChainType
typealias CustomRPC = BaseWallet.CustomRPC
typealias AllChains = BaseWallet.AllChains

extension ChainType {
//enum ChainType: Codable, CaseIterable {
//  enum Key: CodingKey {
//    case rawValue
//  }
//
//  enum CodingError: Error {
//    case unknownValue
//  }
//
//  init(from decoder: Decoder) throws {
//    let container = try decoder.container(keyedBy: Key.self)
//    let rawValue = try container.decode(Int.self, forKey: .rawValue)
//    switch rawValue {
//    case 0:
//      self = .all
//    case 1:
//      self = .eth
//    case 2:
//      self = .ropsten
//    case 3:
//      self = .bsc
//    case 4:
//      self = .bscTestnet
//    case 5:
//      self = .polygon
//    case 6:
//      self = .polygonTestnet
//    case 7:
//      self = .avalanche
//    case 8:
//      self = .avalancheTestnet
//    case 9:
//      self = .cronos
//    case 10:
//      self = .fantom
//    case 11:
//      self = .arbitrum
//    case 12:
//      self = .aurora
//    case 13:
//      self = .solana
//    case 14:
//      self = .klaytn
//    default:
//      throw CodingError.unknownValue
//    }
//  }
//
//  func encode(to encoder: Encoder) throws {
//    var container = encoder.container(keyedBy: Key.self)
//    switch self {
//    case .all:
//      try container.encode(0, forKey: .rawValue)
//    case .eth:
//      try container.encode(1, forKey: .rawValue)
//    case .ropsten:
//      try container.encode(2, forKey: .rawValue)
//    case .bsc:
//      try container.encode(3, forKey: .rawValue)
//    case .bscTestnet:
//      try container.encode(4, forKey: .rawValue)
//    case .polygon:
//      try container.encode(5, forKey: .rawValue)
//    case .polygonTestnet:
//      try container.encode(6, forKey: .rawValue)
//    case .avalanche:
//      try container.encode(7, forKey: .rawValue)
//    case .avalancheTestnet:
//      try container.encode(8, forKey: .rawValue)
//    case .cronos:
//      try container.encode(9, forKey: .rawValue)
//    case .fantom:
//      try container.encode(10, forKey: .rawValue)
//    case .arbitrum:
//      try container.encode(11, forKey: .rawValue)
//    case .aurora:
//      try container.encode(12, forKey: .rawValue)
//    case .solana:
//      try container.encode(13, forKey: .rawValue)
//    case .klaytn:
//      try container.encode(14, forKey: .rawValue)
//    }
//  }

  static func make(chainID: Int) -> ChainType? {
    return ChainType.getAllChain().first { $0.getChainId() == chainID }
  }

  static func getAllChain(includeAll: Bool = false) -> [ChainType] {
    var allChains = ChainType.allCases

    if KNEnvironment.default == .production {
      allChains = allChains.filter { $0 != .ropsten && $0 != .bscTestnet && $0 != .polygonTestnet && $0 != .avalancheTestnet }
    }

    let shouldShowAurora = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.auroraChainIntegration)
    if !shouldShowAurora && KNGeneralProvider.shared.currentChain != .aurora {
      allChains = allChains.filter { $0 != .aurora }
    }

    let shouldShowSolana = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.solanaChainIntegration)
    if !shouldShowSolana && KNGeneralProvider.shared.currentChain != .solana {
      allChains = allChains.filter { $0 != .solana }
    }

    let shouldShowKlaytn = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.klaytnChainIntegration)
    if !shouldShowKlaytn && KNGeneralProvider.shared.currentChain != .klaytn {
      allChains = allChains.filter { $0 != .klaytn }
    }
    if !includeAll {
      allChains = allChains.filter { $0 != .all }
    } else {
      allChains.bringToFront(item: .all)
    }
    return allChains
  }

  static func getAllChainID() -> [Int] {
    return ChainType.getAllChain().map { item in
      return item.customRPC().chainID
    }
  }

  static func getChain(id: Int) -> ChainType? {
    return ChainType.getAllChain().first {
      return $0.customRPC().chainID == id
    }
  }

//  func customRPC() -> CustomRPC {
//    switch self {
//    case .eth:
//      return AllChains.ethMainnetPRC
//    case .ropsten:
//      return AllChains.ethRoptenPRC
//    case .bsc, .all:
//      return AllChains.bscMainnetPRC
//    case .bscTestnet:
//      return AllChains.bscRoptenPRC
//    case .polygon:
//      return AllChains.polygonMainnetPRC
//    case .polygonTestnet:
//      return AllChains.polygonRoptenPRC
//    case .avalanche:
//      return AllChains.avalancheMainnetPRC
//    case .avalancheTestnet:
//      return AllChains.avalancheRoptenPRC
//    case .cronos:
//        return AllChains.cronosMainnetRPC
//    case .fantom:
//        return AllChains.fantomMainnetRPC
//    case .arbitrum:
//        return AllChains.arbitrumMainnetRPC
//    case .aurora:
//      return AllChains.auroraMainnetRPC
//    case .solana:
//      return AllChains.solana
//    case .klaytn:
//      return AllChains.klaytnMainnetRPC
//    }
//  }
//
//  func isSupportedEIP1559() -> Bool {
//    switch self {
//    case .eth, .avalanche, .polygon:
//      return true
//    default:
//      return false
//    }
//  }
//
//  func apiChainPath() -> String {
//    return self.customRPC().apiChainPath
//  }
//
//  func chainPath() -> String {
//    return "/\(self.apiChainPath())"
//  }
//
//  func proxyAddress() -> String {
//    return self.customRPC().proxyAddress.lowercased()
//  }
//
//  func getChainId() -> Int {
//    return self.customRPC().chainID
//  }
//
//  func chainName() -> String {
//    if self == .all {
//      return "All Networks"
//    }
//    return self.customRPC().name
//  }
//
//  func chainIcon() -> UIImage? {
//    if self == .all {
//      return UIImage(named: "chain_all_icon")
//    }
//    return UIImage(named: self.customRPC().chainIcon)
//  }
//
  func squareIcon() -> UIImage {
    switch self {
    case .all:
      return Images.allNetworkSquare
    case .eth:
      return Images.chainEthSquare
    case .ropsten:
      return Images.chainEthSquare
    case .bsc:
      return Images.chainBscSquare
    case .bscTestnet:
      return Images.chainBscSquare
    case .polygon:
      return Images.chainPolygonSquare
    case .polygonTestnet:
      return Images.chainPolygonSquare
    case .avalanche:
      return Images.chainAvaxSquare
    case .avalancheTestnet:
      return Images.chainAvaxSquare
    case .cronos:
      return Images.chainCronosSquare
    case .fantom:
      return Images.chainFantomSquare
    case .arbitrum:
      return Images.chainArbitrumSquare
    case .aurora:
      return Images.chainAuroraSquare
    case .solana:
      return Images.chainSolanaSquare
    case .klaytn:
      return Images.chainKlaytnSquare
    case .optimism:
      return Images.chainOptimismSquare
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

  static func allLendingDistributionPlatform() -> [String] {
    var result: [String] = []

    ChainType.getAllChain().forEach { e in
      let plaform = e.lendingDistributionPlatform()
      if !plaform.isEmpty {
        result.append(plaform)
      }
    }

    return result
  }

  func quoteTokenObject() -> TokenObject {
    let token = KNSupportedTokenStorage.shared.supportedToken.first { (token) -> Bool in
      return token.symbol == self.customRPC().quoteToken && token.address == self.customRPC().quoteTokenAddress
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
    case .arbitrum, .aurora, .klaytn:
      return "\(self.customRPC().chainID)" + "-" + KNEnvironment.default.displayName + "-"
    default:
      return self.customRPC().quoteToken.lowercased() + "-" + KNEnvironment.default.displayName + "-"
    }
  }

  func defaultToSwapToken() -> TokenObject {
    switch self {
    case .eth:
      return KNSupportedTokenStorage.shared.kncToken
    case .ropsten:
      return KNSupportedTokenStorage.shared.kncToken
    case .bsc:
        return KNSupportedTokenStorage.shared.busdToken
    case .bscTestnet:
        return KNSupportedTokenStorage.shared.busdToken
    case .polygon:
        return KNSupportedTokenStorage.shared.usdcToken
    case .polygonTestnet:
        return KNSupportedTokenStorage.shared.usdcToken
    case .avalanche:
        return KNSupportedTokenStorage.shared.usdceToken
    case .avalancheTestnet:
        return KNSupportedTokenStorage.shared.usdceToken
    case .cronos:
        return KNSupportedTokenStorage.shared.usdcToken
    case .fantom:
        return KNSupportedTokenStorage.shared.usdcToken
    case .arbitrum:
        return KNSupportedTokenStorage.shared.usdcToken
    case .aurora:
        return KNSupportedTokenStorage.shared.usdcToken
    case .solana:
        return KNSupportedTokenStorage.shared.usdcToken
    case .klaytn:
      return KNSupportedTokenStorage.shared.usdcToken
    case .optimism:
      return KNSupportedTokenStorage.shared.usdcToken
    case .all:
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

//  var supportMultisend: Bool {
//    switch self {
//    case .solana:
//      return false
//    default:
//      return true
//    }
//  }
//
//  func isSupportSwap() -> Bool {
//    switch self {
//    case .solana:
//      return false
//    default:
//      return true
//    }
//  }
//
//  func isSupportedHistoryAPI() -> Bool {
//    switch self {
//    case .cronos:
//      return false
//    default:
//      return true
//    }
//  }
//
//  func isSupportedBridge() -> Bool {
//    switch self {
//    case .solana:
//      return false
//    default:
//      return true
//    }
//  }
//
//  var isEVM: Bool {
//    switch self {
//    case .solana:
//      return false
//    default:
//      return true
//    }
//  }
//  case all
//  case eth
//  case ropsten
//  case bsc
//  case bscTestnet
//  case polygon
//  case polygonTestnet
//  case avalanche
//  case avalancheTestnet
//  case cronos
//  case fantom
//  case arbitrum
//  case aurora
//  case solana
//  case klaytn
//}
  
}

extension CurrencyMode {
  
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
  
}
