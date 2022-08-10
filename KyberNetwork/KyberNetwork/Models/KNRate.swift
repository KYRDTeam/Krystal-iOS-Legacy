// Copyright SIX DAY LLC. All rights reserved.

import BigInt

// All rate should be in ether unit (18 decimals)
class KNRate: NSObject {

  let source: String
  let dest: String
  let rate: BigInt
  let minRate: BigInt

  init(dictionary: JSONDictionary, isUSDRate: Bool = false) throws {
    if isUSDRate {
      source = dictionary["symbol"] as? String ?? ""
      dest = "USD"
      if let rateDouble = dictionary["price"] as? Double {
        rate = BigInt(rateDouble * Double(EthereumUnit.ether.rawValue))
        minRate = rate * BigInt(97) / BigInt(100)
        if isDebug { print("Rate from \(source) to USD: \(EtherNumberFormatter.full.string(from: rate))") }
      } else {
        throw CastError(actualValue: String.self, expectedType: Double.self)
      }
    } else {
      let symbol = dictionary["symbol"] as? String ?? ""
      source = symbol
      dest = "ETH"
      if let rateDouble = dictionary["price"] as? Double,
        let to = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == symbol }) {
        let minRateDouble = rateDouble * 97.0 / 100.0
        rate = BigInt(rateDouble * Double(EthereumUnit.ether.rawValue))
        minRate = BigInt(minRateDouble)
        if isDebug {
          print("Rate from \(source) to \(dest): \(rate.string(decimals: to.decimals, minFractionDigits: 0, maxFractionDigits: 10))")
        }
      } else {
        throw CastError(actualValue: String.self, expectedType: BigInt.self)
      }
    }
  }

  init(cachedDict: JSONDictionary) throws {
    source = cachedDict["source"] as? String ?? ""
    let tokenSymbol = cachedDict["dest"] as? String ?? ""
    dest = tokenSymbol
    if let rateString = cachedDict["rate"] as? String, let rateBig = BigInt(rateString),
      let token = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == tokenSymbol }) {
      rate = rateBig / BigInt(10).power(18 - token.decimals)
      minRate = rate * BigInt(97) / BigInt(100)
    } else {
      throw CastError(actualValue: String.self, expectedType: BigInt.self)
    }
  }

  init(source: String, dest: String, rate: Double, decimals: Int) {
    self.source = source
    self.dest = dest
    self.rate = BigInt(rate * pow(10.0, Double(decimals)))
    // 3% from rate
    self.minRate = self.rate * BigInt(97) / BigInt(100)
  }
}

extension KNRate {
  static func rateETH(from trackerRate: KNTrackerRate) -> KNRate {
    return KNRate(
      source: trackerRate.tokenSymbol,
      dest: "ETH",
      rate: trackerRate.tokenSymbol == "ETH" ? 1.0 : trackerRate.rateETHNow,
      decimals: 18
    )
  }

  static func rateUSD(from trackerRate: KNTrackerRate) -> KNRate {
    return KNRate(
      source: trackerRate.tokenSymbol,
      dest: "USD",
      rate: trackerRate.rateUSDNow,
      decimals: 18
    )
  }
}

// MARK: - RateResponse
struct RateResponse: Codable {
    let timestamp: Int
    let rates: [Rate]
}

// MARK: - Rate
class Rate: Codable {
  var rate: String
  let platform, platformShort: String
  let platformIcon: String
  let hint: String
  let amount: String
  let tradePath: [String]
  var estimatedGas: Int
  var priceImpact: Int
}
