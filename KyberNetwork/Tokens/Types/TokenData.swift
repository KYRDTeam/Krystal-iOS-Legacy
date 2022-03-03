//
//  TokenData.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/29/21.
//

import Foundation
import BigInt

class Token: Codable, Equatable, Hashable {
  var address: String
  var name: String
  var symbol: String
  var decimals: Int
  var logo: String
  var tag: String?

  init(dictionary: JSONDictionary) {
    self.name = dictionary["name"] as? String ?? ""
    self.symbol = dictionary["symbol"] as? String ?? ""
    self.address = (dictionary["address"] as? String ?? "").lowercased()
    self.decimals = dictionary["decimals"] as? Int ?? 0
    self.logo = dictionary["logo"] as? String ?? ""
    if let tag = dictionary["tag"] as? String, !tag.isEmpty {
      self.tag = tag
    }
  }
  
  static func blankToken() -> Token {
    return Token(name: "Search Token", symbol: "Search Token", address: "", decimals: 0, logo: "")
  }
  
  func isBlank() -> Bool {
    return self.address == ""
  }

  init(name: String, symbol: String, address: String, decimals: Int, logo: String) {
    self.name = name
    self.symbol = symbol
    self.address = address
    self.decimals = decimals
    self.logo = logo
  }

  var isETH: Bool {
    return self.symbol == "ETH"
  }
  
  var isBNB: Bool {
    return self.address.lowercased() == Constants.bnbAddress.lowercased()
  }

  var isMatic: Bool {
    return self.address.lowercased() == Constants.maticAddress.lowercased()
  }

  var isAvax: Bool {
    return self.address.lowercased() == Constants.avaxAddress.lowercased()
  }

  var isCro: Bool {
    return self.address.lowercased() == Constants.cronosAddress.lowercased()
  }

  var isFtm: Bool {
    return self.address.lowercased() == Constants.fantomAddress.lowercased()
  }

  var isQuoteToken: Bool {
    return self.isETH || self.isBNB || self.isMatic || self.isAvax || self.isFtm || self.isCro
  }

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
    case .bnb:
      return price.bnb
    case .matic:
      return price.matic
    case .avax:
      return price.avax
    case .cro:
      return price.cro
    case .ftm:
      return price.ftm
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
    case .bnb:
      return price.bnb
    case .matic:
      return price.matic
    case .avax:
      return price.avax
    case .cro:
      return price.cro
    case .ftm:
      return price.ftm
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
    case .bnb:
      return price.bnb24hChange
    case .matic:
      return price.matic24hChange
    case .avax:
      return price.avax24hChange
    case .cro:
      return price.cro24hChange
    case .ftm:
      return price.ftm24hChange
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
    case .bnb:
      return price.bnb24hVol
    case .matic:
      return price.matic24hVol
    case .avax:
      return price.avax24hVol
    case .cro:
      return price.cro24hVol
    case .ftm:
      return price.ftm24hVol
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
    case .bnb:
      return price.bnbMarketCap
    case .matic:
      return price.maticMarketCap
    case .avax:
      return price.avaxMarketCap
    case .cro:
      return price.croMarketCap
    case .ftm:
      return price.ftmMarketCap
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
  var eth: Double
  var ethMarketCap: Double
  var eth24hVol: Double
  var eth24hChange: Double
  var btc: Double
  var btcMarketCap: Double
  var btc24hVol: Double
  var btc24hChange: Double
  var bnb: Double
  var bnbMarketCap: Double
  var bnb24hVol: Double
  var bnb24hChange: Double
  var matic: Double
  var maticMarketCap: Double
  var matic24hVol: Double
  var matic24hChange: Double
  var avax: Double
  var avaxMarketCap: Double
  var avax24hVol: Double
  var avax24hChange: Double
  var cro: Double
  var croMarketCap: Double
  var cro24hVol: Double
  var cro24hChange: Double
  var ftm: Double
  var ftmMarketCap: Double
  var ftm24hVol: Double
  var ftm24hChange: Double
  
  init(address: String, quotes: [String: Quote]) {
    self.address = address
    
    self.usd = quotes["usd"]?.price ?? 0.0
    self.usdMarketCap = quotes["usd"]?.marketCap ?? 0.0
    self.usd24hVol = quotes["usd"]?.volume24H ?? 0.0
    self.usd24hChange = quotes["usd"]?.price24HChangePercentage ?? 0.0
    
    self.eth = quotes["eth"]?.price ?? 0.0
    self.ethMarketCap = quotes["eth"]?.marketCap ?? 0.0
    self.eth24hVol = quotes["eth"]?.volume24H ?? 0.0
    self.eth24hChange = quotes["eth"]?.price24HChangePercentage ?? 0.0
    
    self.btc = quotes["btc"]?.price ?? 0.0
    self.btcMarketCap = quotes["btc"]?.marketCap ?? 0.0
    self.btc24hVol = quotes["btc"]?.volume24H ?? 0.0
    self.btc24hChange = quotes["btc"]?.price24HChangePercentage ?? 0.0
    
    self.bnb = quotes["bnb"]?.price ?? 0.0
    self.bnbMarketCap = quotes["bnb"]?.marketCap ?? 0.0
    self.bnb24hVol = quotes["bnb"]?.volume24H ?? 0.0
    self.bnb24hChange = quotes["bnb"]?.price24HChangePercentage ?? 0.0
    
    self.matic = quotes["matic"]?.price ?? 0.0
    self.maticMarketCap = quotes["matic"]?.marketCap ?? 0.0
    self.matic24hVol = quotes["matic"]?.volume24H ?? 0.0
    self.matic24hChange = quotes["matic"]?.price24HChangePercentage ?? 0.0
    
    self.avax = quotes["avax"]?.price ?? 0.0
    self.avaxMarketCap = quotes["avax"]?.marketCap ?? 0.0
    self.avax24hVol = quotes["avax"]?.volume24H ?? 0.0
    self.avax24hChange = quotes["avax"]?.price24HChangePercentage ?? 0.0
    
    self.cro = quotes["cro"]?.price ?? 0.0
    self.croMarketCap = quotes["cro"]?.marketCap ?? 0.0
    self.cro24hVol = quotes["cro"]?.volume24H ?? 0.0
    self.cro24hChange = quotes["cro"]?.price24HChangePercentage ?? 0.0
    
    self.ftm = quotes["ftm"]?.price ?? 0.0
    self.ftmMarketCap = quotes["ftm"]?.marketCap ?? 0.0
    self.ftm24hVol = quotes["ftm"]?.volume24H ?? 0.0
    self.ftm24hChange = quotes["ftm"]?.price24HChangePercentage ?? 0.0
  }
  
  func priceWithCurrency(currencyMode: CurrencyMode) -> Double {
    switch currencyMode {
      case .usd:
        return self.usd
      case .eth:
        return self.eth
      case .btc:
        return self.btc
      case .bnb:
        return self.bnb
      case .matic:
        return self.matic
      case .avax:
        return self.avax
      case .cro:
        return self.cro
      case .ftm:
        return self.ftm
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

struct LendingBalance: Codable {
  let name: String
  let symbol: String
  let address: String
  let decimals: Int
  let supplyRate: Double
  let stableBorrowRate: Double
  let variableBorrowRate: Double
  let supplyBalance: String
  let stableBorrowBalance: String
  let variableBorrowBalance: String
  let interestBearingTokenSymbol: String
  let interestBearingTokenAddress: String
  let interestBearingTokenDecimal: Int
  let interestBearningTokenBalance: String
  let requiresApproval: Bool
  let logo: String

  init(dictionary: JSONDictionary) {
    self.name = dictionary["name"] as? String ?? ""
    self.symbol = dictionary["symbol"] as? String ?? ""
    self.address = (dictionary["address"] as? String ?? "").lowercased()
    self.decimals = dictionary["decimals"] as? Int ?? 0
    self.supplyRate = dictionary["supplyRate"] as? Double ?? 0.0
    self.stableBorrowRate = dictionary["stableBorrowRate"] as? Double ?? 0.0
    self.variableBorrowRate = dictionary["variableBorrowRate"] as? Double ?? 0.0
    self.supplyBalance = dictionary["supplyBalance"] as? String ?? ""
    self.stableBorrowBalance = dictionary["stableBorrowBalance"] as? String ?? ""
    self.variableBorrowBalance = dictionary["variableBorrowBalance"] as? String ?? ""
    self.interestBearingTokenSymbol = dictionary["interestBearingTokenSymbol"] as? String ?? ""
    self.interestBearingTokenAddress = dictionary["interestBearingTokenAddress"] as? String ?? ""
    self.interestBearingTokenDecimal = dictionary["interestBearingTokenDecimal"] as? Int ?? 0
    self.interestBearningTokenBalance = dictionary["interestBearingTokenBalance"] as? String ?? ""
    self.requiresApproval = dictionary["requiresApproval"] as? Bool ?? true
    self.logo = dictionary["logo"] as? String ?? ""
  }

  func getValueBigInt(_ currency: CurrencyMode) -> BigInt {
    let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: self.address, currency: currency)
    let balanceBigInt = BigInt(self.supplyBalance) ?? BigInt(0)
    return balanceBigInt * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(self.decimals)
  }

  var hasSmallAmount: Bool {
    guard let balanceBigInt = BigInt(self.supplyBalance) else { return true }
    let limit = BigInt(0.00001 * pow(10.0, Double(self.decimals)))
    return balanceBigInt < limit
  }
}

struct LendingPlatformBalance: Codable {
  let name: String
  let balances: [LendingBalance]
}

struct LendingDistributionBalance: Codable {
  let name: String
  let symbol: String
  let address: String
  let decimal: Int
  let current: String
  let unclaimed: String
  let logo: String

  init(dictionary: JSONDictionary) {
    self.name = dictionary["name"] as? String ?? ""
    self.symbol = dictionary["symbol"] as? String ?? ""
    self.address = (dictionary["address"] as? String ?? "").lowercased()
    self.decimal = dictionary["decimal"] as? Int ?? 0
    self.current = dictionary["current"] as? String ?? ""
    self.unclaimed = dictionary["unclaimed"] as? String ?? ""
    self.logo = dictionary["logo"] as? String ?? ""
  }
  
  func getValueBigInt(_ currency: CurrencyMode) -> BigInt {
    let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: self.address, currency: currency)
    let balanceBigInt = BigInt(self.unclaimed) ?? BigInt(0)
    return balanceBigInt * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(self.decimal)
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
    let balance = BalanceStorage.shared.balanceForAddress(self.address)
    return BigInt(balance?.balance ?? "") ?? BigInt(0)
  }
  
  func toObject() -> TokenObject {
    return TokenObject(name: self.name, symbol: self.symbol, address: self.address, decimals: self.decimals, logo: "")
  }

  var placeholderValue: BigInt {
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
