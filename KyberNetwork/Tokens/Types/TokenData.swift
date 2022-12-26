//
//  TokenData.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/29/21.
//

import Foundation
import BigInt
import Services

extension Token {
//  var address: String
//  var name: String
//  var symbol: String
//  var decimals: Int
//  var logo: String
//  var tag: String?
//
//  init(dictionary: JSONDictionary) {
//    self.name = dictionary["name"] as? String ?? ""
//    self.symbol = dictionary["symbol"] as? String ?? ""
//    self.address = (dictionary["address"] as? String ?? "")
//    self.decimals = dictionary["decimals"] as? Int ?? 0
//    self.logo = dictionary["logo"] as? String ?? ""
//    if let tag = dictionary["tag"] as? String, !tag.isEmpty {
//      self.tag = tag
//    }
//  }
//
  static func blankToken() -> Token {
    return Token(name: "Search Token", symbol: "Search Token", address: "", decimals: 0, logo: "")
  }
  
  func isBlank() -> Bool {
    return self.address == ""
  }

//  init(name: String, symbol: String, address: String, decimals: Int, logo: String) {
//    self.name = name
//    self.symbol = symbol
//    self.address = address
//    self.decimals = decimals
//    self.logo = logo
//  }

  var isETH: Bool {
    return self.symbol == "ETH"
  }
  
  var isBNB: Bool {
    return self.address.lowercased() == AllChains.bscMainnetPRC.quoteTokenAddress.lowercased()
  }

  var isMatic: Bool {
    return self.address.lowercased() == AllChains.polygonMainnetPRC.quoteTokenAddress.lowercased()
  }

  var isAvax: Bool {
    return self.address.lowercased() == AllChains.avalancheMainnetPRC.quoteTokenAddress.lowercased()
  }

  var isCro: Bool {
    return self.address.lowercased() == AllChains.cronosMainnetRPC.quoteTokenAddress.lowercased()
  }

  var isFtm: Bool {
    return self.address.lowercased() == AllChains.fantomMainnetRPC.quoteTokenAddress.lowercased()
  }
  
  var isKlay: Bool {
    return self.address.lowercased() == AllChains.klaytnMainnetRPC.quoteTokenAddress.lowercased()
  }

//  var isQuoteToken: Bool {
//    return self.isETH || self.isBNB || self.isMatic || self.isAvax || self.isFtm || self.isCro || self.isKlay
//  }

  func toObject(isCustom: Bool = false) -> TokenObject {
    let tokenObject = TokenObject(name: self.name, symbol: self.symbol, address: self.address, decimals: self.decimals, logo: self.logo)
    tokenObject.isCustom = isCustom
    tokenObject.volumn = self.getVol(.usd)
    tokenObject.tag = self.tag
    return tokenObject
  }

  func getBalanceBigInt() -> BigInt {
    let balance = BalanceStorage.shared.balanceForAddress(self.address)
    return BigInt(balance?.balance ?? "") ?? BigInt(0)
  }
  
  func getBalanceBigIntForChain(chainType: ChainType) -> BigInt {
    let balance = BalanceStorage.shared.balanceForAddressInChain(self.address, chainType: chainType)
    return BigInt(balance?.balance ?? "") ?? BigInt(0)
  }
  
  func getTokenPrice() -> TokenPrice {
    let price = KNTrackerRateStorage.shared.getPriceWithAddress(self.address) ?? TokenPrice(address: self.address, quotes: [:])
    return price
  }
  
  func getTokenPrice(chainType: ChainType) -> TokenPrice {
    let price = KNTrackerRateStorage.shared.getPriceWithAddress(self.address, chainType: chainType) ?? TokenPrice(address: self.address, quotes: [:])
    return price
  }

  func getTokenLastPrice(_ mode: CurrencyMode) -> Double {
    let price = self.getTokenPrice()
    switch mode {
    case .usd:
      return price.usd
    case .eth:
      return price.eth
    case .btc:
      return price.btc
    default:
      return price.quote
    }
  }

  func getTokenLastPrice(_ mode: CurrencyMode, chainType: ChainType) -> Double {
    let price = self.getTokenPrice(chainType: chainType)
    switch mode {
    case .usd:
      return price.usd
    case .eth:
      return price.eth
    case .btc:
      return price.btc
    default:
      return price.quote
    }
  }
  
  func getTokenChange24(_ mode: CurrencyMode) -> Double {
    let price = self.getTokenPrice()
    switch mode {
    case .usd:
      return price.usd24hChange
    case .eth:
      return price.eth24hChange
    case .btc:
      return price.btc24hChange
    default:
      return price.quote24hChange
    }
  }

  func getVol(_ mode: CurrencyMode) -> Double {
    let price = self.getTokenPrice()
    switch mode {
    case .usd:
      return price.usd24hVol
    case .eth:
      return price.eth24hVol
    case .btc:
      return price.btc24hVol
    default:
      return price.quote24hVol
    }
  }
  
  func getMarketCap(_ mode: CurrencyMode) -> Double {
    let price = self.getTokenPrice()
    switch mode {
    case .usd:
      return price.usdMarketCap
    case .eth:
      return price.ethMarketCap
    case .btc:
      return price.btcMarketCap
    default:
      return price.quoteMarketCap
    }
  }
  
  static func == (lhs: Token, rhs: Token) -> Bool {
    return lhs.address.lowercased() == rhs.address.lowercased() && lhs.decimals == rhs.decimals
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(self.address)
  }
  
  func getValueBigInt(_ currency: CurrencyMode) -> BigInt {
    let rateBigInt = BigInt(self.getTokenLastPrice(currency) * pow(10.0, 18.0))
    let valueBigInt = self.getBalanceBigInt() * rateBigInt / BigInt(10).power(self.decimals)
    return valueBigInt
  }
}

class TokenBalance: Codable {
  let address: String
  var balance: String
  
  init(address: String, balance: String) {
    self.address = address
    self.balance = balance
  }
}

struct EarnToken: Codable {
  let address: String
  let lendingPlatforms: [LendingPlatformData]
}

class TokenPrice: Codable {
  let address: String
  var usd: Double
  var usdMarketCap: Double
  var usd24hVol: Double
  var usd24hChange: Double
  var btc: Double
  var btcMarketCap: Double
  var btc24hVol: Double
  var btc24hChange: Double
  var eth: Double
  var ethMarketCap: Double
  var eth24hVol: Double
  var eth24hChange: Double
  var quote: Double
  var quoteMarketCap: Double
  var quote24hVol: Double
  var quote24hChange: Double

  init(address: String, quotes: [String: Quote]) {
    self.address = address
    self.usd = quotes["usd"]?.price ?? 0.0
    self.usdMarketCap = quotes["usd"]?.marketCap ?? 0.0
    self.usd24hVol = quotes["usd"]?.volume24H ?? 0.0
    self.usd24hChange = quotes["usd"]?.price24HChangePercentage ?? 0.0
    self.btc = quotes["btc"]?.price ?? 0.0
    self.btcMarketCap = quotes["btc"]?.marketCap ?? 0.0
    self.btc24hVol = quotes["btc"]?.volume24H ?? 0.0
    self.btc24hChange = quotes["btc"]?.price24HChangePercentage ?? 0.0
    self.eth = quotes["eth"]?.price ?? 0.0
    self.ethMarketCap = quotes["eth"]?.marketCap ?? 0.0
    self.eth24hVol = quotes["eth"]?.volume24H ?? 0.0
    self.eth24hChange = quotes["eth"]?.price24HChangePercentage ?? 0.0
    
    let quote = KNGeneralProvider.shared.currentChain.quoteToken().lowercased()
    self.quote = quotes[quote]?.price ?? 0.0
    self.quoteMarketCap = quotes[quote]?.marketCap ?? 0.0
    self.quote24hVol = quotes[quote]?.volume24H ?? 0.0
    self.quote24hChange = quotes[quote]?.price24HChangePercentage ?? 0.0
  }
  
  func priceWithCurrency(currencyMode: CurrencyMode) -> Double {
    switch currencyMode {
    case .usd:
      return self.usd
    case .eth:
      return self.eth
    case .btc:
      return self.btc
    default:
      return self.quote
    }
  }
}

class FavedToken: Codable {
  let address: String
  var status: Bool
  
  init(address: String, status: Bool) {
    self.address = address
    self.status = status
  }
}

class LendingBalance: Codable {

  let address, symbol, name: String
  let decimals: Int
  let logo: String
  let tag: Tag
  let supplyRate, stableBorrowRate, variableBorrowRate: Double
  let distributionSupplyRate, distributionBorrowRate: Double?
  let supplyBalance, stableBorrowBalance, variableBorrowBalance, interestBearingTokenSymbol: String
  let interestBearingTokenAddress: String
  let interestBearingTokenDecimals: Int
  let interestBearingTokenBalance: String
  let requiresApproval: Bool
  let supplyQuotes, stableBorrowQuotes, variableBorrowQuotes: [String: LendingQuote]
  
  var chainType: ChainType?

  func getValueBigInt(_ currency: CurrencyMode) -> BigInt {
    let balanceBigInt = BigInt(self.supplyBalance) ?? BigInt(0)
    return balanceBigInt * BigInt(self.getPriceDouble(currency) * pow(10.0, 18.0)) / BigInt(10).power(self.decimals)
  }

  var hasSmallAmount: Bool {
    guard let balanceBigInt = BigInt(self.supplyBalance) else { return true }
    let limit = BigInt(0.00001 * pow(10.0, Double(self.decimals)))
    return balanceBigInt < limit
  }
  
  func getPriceDouble(_ currency: CurrencyMode) -> Double {
    return self.supplyQuotes[currency.toString()]?.price ?? 0
  }
}

// MARK: - Quote
struct LendingQuote: Codable {
    let symbol: String
    let price, priceChange24HPercentage, value: Double

    enum CodingKeys: String, CodingKey {
        case symbol, price
        case priceChange24HPercentage = "priceChange24hPercentage"
        case value
    }
}

//enum Symbol: String, Codable {
//    case bnb = "BNB"
//    case btc = "BTC"
//    case usd = "USD"
//}

enum Tag: String, Codable {
    case scam = "SCAM"
    case unverified = "UNVERIFIED"
    case verified = "VERIFIED"
}

// MARK: - AllLendingBalanceResponse
struct AllLendingBalanceResponse: Codable {
    let data: [LendingBalanceData]
}

// MARK: - LendingBalanceData
struct LendingBalanceData: Codable {
    let chainName: String
    let chainID: Int
    let chainLogo: String
    let balances: [LendingPlatformBalance]?
}

class LendingPlatformBalance: Codable {
  let name: String
  let balances: [LendingBalance]
  var chainType: ChainType? {
    didSet {
      self.balances.forEach { e in
        e.chainType = self.chainType
      }
    }
  }
  
  init(name: String, balances: [LendingBalance]) {
    self.name = name
    self.balances = balances
  }
}

// MARK: - AllLendingDistributionBalanceResponse
struct AllLendingDistributionBalanceResponse: Codable {
    let data: [AllLendingDistributionBalanceData]
}

// MARK: - Datum
struct AllLendingDistributionBalanceData: Codable {
    let chainName: String
    let chainID: Int
    let chainLogo: String
    let balances: [LendingDistributionBalance]?
}

class LendingDistributionBalance: Codable {
  let name: String
  let symbol: String
  let address: String
  let decimal: Int
  let current: String
  let unclaimed: String
  let logo: String
  let currentQuote, unclaimedQuote: [String: LendingQuote]
  
  var chainType: ChainType?
  
  func getValueBigInt(_ currency: CurrencyMode) -> BigInt {
//    let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: self.address, currency: currency)
    let balanceBigInt = BigInt(self.unclaimed) ?? BigInt(0)
    return balanceBigInt * BigInt(self.getPriceDouble(currency) * pow(10.0, 18.0)) / BigInt(10).power(self.decimal)
  }
  
  func getPriceDouble(_ currency: CurrencyMode) -> Double {
    return self.currentQuote[currency.toString()]?.price ?? 0.0
  }
}

struct TokenData: Codable, Equatable {
  let address: String
  let name: String
  let symbol: String
  let decimals: Int
  let lendingPlatforms: [LendingPlatformData]
  let logo: String

  static func == (lhs: TokenData, rhs: TokenData) -> Bool {
    return lhs.address.lowercased() == rhs.address.lowercased()
  }

  var isETH: Bool {
    return self.symbol == "ETH"
  }

  var isBNB: Bool {
    return self.symbol == "BNB"
  }

  var isMatic: Bool {
    return self.symbol == "MATIC"
  }

  var isAvax: Bool {
    return self.symbol == "AVAX"
  }
  
  var isFTM: Bool {
    return self.symbol == "FTM"
  }
  
  var isCRO: Bool {
    return self.symbol == "CRO"
  }

  var isQuoteToken: Bool {
    return self.isETH || self.isBNB || self.isMatic || self.isAvax || self.isFTM || self.isCRO
  }

  func getBalanceBigInt() -> BigInt {
    guard !KNGeneralProvider.shared.isBrowsingMode else {
      return BigInt(0)
    }
    let balance = BalanceStorage.shared.balanceForAddress(self.address)
    return BigInt(balance?.balance ?? "") ?? BigInt(0)
  }
  
  func toObject() -> TokenObject {
    return TokenObject(name: self.name, symbol: self.symbol, address: self.address, decimals: self.decimals, logo: "")
  }

  var placeholderValue: BigInt {
    guard self.decimals > 2 else {
      return BigInt(Int(pow(10.0, Double(self.decimals))))
    }
    let value = Int(0.001 * pow(10.0, Double(self.decimals)))
    return BigInt(value)
  }
  
  var isWrapToken: Bool {
    return self.symbol.lowercased() == "weth"
    || self.symbol.lowercased() == "wbnb"
    || self.symbol.lowercased() == "wavax"
    || self.symbol.lowercased() == "wmatic"
    || self.symbol.lowercased() == "wftm"
    || self.symbol.lowercased() == "wcro"
  }
}

struct LendingPlatformData: Codable {
  let name: String
  let supplyRate: Double
  let stableBorrowRate: Double
  let variableBorrowRate: Double
  let distributionSupplyRate: Double
  let distributionBorrowRate: Double

  var isCompound: Bool {
    return self.name == "Compound" || self.name == "Venus"
  }

  var compondPrefix: String {
    return KNGeneralProvider.shared.currentChain == .eth ? "c" : "v"
  }
}
