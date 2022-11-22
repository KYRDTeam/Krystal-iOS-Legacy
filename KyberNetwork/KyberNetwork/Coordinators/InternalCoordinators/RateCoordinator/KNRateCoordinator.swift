// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import Moya
import BigInt
import Sentry
import Utilities

/*

 This coordinator controls the fetching exchange token + usd rates,
 running timer interval to frequently fetch data from /getRate and /getRateUSD APIs

*/

class KNRateCoordinator {
  static let shared = KNRateCoordinator()

  fileprivate let provider = MoyaProvider<KNTrackerService>()
  fileprivate let userInfoProvider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])

  fileprivate var cacheTokenETHRates: [String: KNRate] = [:] // Rate token to ETH
  fileprivate var cachedProdTokenRates: [String: KNRate] = [:] // Prod cached rate to compare when swapping
  var cachedMarket: [KNMarket] = []
  var cachedMarketVolume: [String: Double] = [:]
  fileprivate var cacheRateTimer: Timer?

  fileprivate var cachedUSDRates: [String: KNRate] = [:] // Rate token to USD

  fileprivate var exchangeTokenRatesTimer: Timer?
  fileprivate var isLoadingExchangeTokenRates: Bool = false
  fileprivate var platformFeeTimer: Timer?

  fileprivate var lastRefreshTime: Date = Date()
  var currentSymPair: (String, String) = ("KNC", "ETH")
  var requestingChain = KNGeneralProvider.shared.currentChain

  func getCacheRate(from: String, to: String) -> KNRate? {
    if to == "ETH" { return self.cacheTokenETHRates[from] }
    if to == "USD" { return self.cachedUSDRates[from] }
    return self.cachedProdTokenRates["\(from)_\(to)"]
  }

  init() {}

  func resume() {
    self.loadTokenPrice()
    self.cacheRateTimer?.invalidate()
    self.cacheRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds60,
      repeats: true,
      block: { [weak self] timer in
        self?.loadTokenPrice()
      }
    )
  }

  func pause() {
    self.cacheRateTimer?.invalidate()
    self.cacheRateTimer = nil
  }


  @objc func fetchPlatformFee(_ sender: Any?) {
    self.userInfoProvider.requestWithFilter(.getPlatformFee) { [weak self] (response) in
      guard let _ = self else { return }
      switch response {
      case .success(let resp):
        do {
          let _ = try resp.filterSuccessfulStatusCodes()
          let json = try resp.mapJSON() as? JSONDictionary ?? [:]
          if let isSuccess = json["success"] as? Bool,
            isSuccess == true,
            let fee = json["fee"] as? NSNumber {
            UserDefaults.standard.set(fee.intValue, forKey: KNAppTracker.kPlatformFeeKey)
          }
        } catch {
        }
      case .failure:
        break
      }
    }
  }

  func getMarketWith(name: String) -> KNMarket? {
    guard !self.cachedMarket.isEmpty else {
      return KNMarket(dict: ["pair": name])
    }
    let market = self.cachedMarket.first { (market) -> Bool in
      return market.pair == name
    }
    return market
  }

  func getMarketVolume(pair: String) -> Double {
    let firstSymbol = pair.components(separatedBy: "_").first ?? ""
    let secondSymbol = pair.components(separatedBy: "_").last ?? ""
    if firstSymbol == "ETH" || firstSymbol == "WETH" {
      return (self.cachedMarketVolume["ETH_\(secondSymbol)"] ?? 0) + (self.cachedMarketVolume["WETH_\(secondSymbol)"] ?? 0)
    }
    if secondSymbol == "ETH" || secondSymbol == "WETH" {
      return (self.cachedMarketVolume["\(firstSymbol)_ETH"] ?? 0) + (self.cachedMarketVolume["\(firstSymbol)_WETH"] ?? 0)
    }
    return self.cachedMarketVolume[pair] ?? 0
  }

  func getCachedSourceAmount(from: TokenObject, to: TokenObject, destAmount: Double, completion: @escaping (Result<BigInt?, AnyError>) -> Void) {
    let fromAddr = from.contract
    let toAddr = to.contract

    DispatchQueue.global().async {
      self.provider.requestWithFilter(.getSourceAmount(src: fromAddr, dest: toAddr, amount: destAmount)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let resp):
            do {
              let _ = try resp.filterSuccessfulStatusCodes()
              let json = try resp.mapJSON() as? JSONDictionary ?? [:]
              if let err = json["error"] as? Bool, !err, let value = json["data"] as? String, let amount = value.fullBigInt(decimals: from.decimals) {
                // add platform fee
                completion(.success(amount * BigInt(10000 + KNAppTracker.getPlatformFee(source: from.contract, dest: to.contract)) / BigInt(10000)))
              } else {
                completion(.success(nil))
              }
            } catch let error {
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func loadTokenPrice() {

    guard !(self.isLoadingExchangeTokenRates && self.requestingChain == KNGeneralProvider.shared.currentChain) else { return }
    let tx = SentrySDK.startTransaction(
      name: "load-token-price-request",
      operation: "load-token-price-operation"
    )

    let tokenAddress = KNSupportedTokenStorage.shared.getActiveSupportedToken().map { (token) -> String in
      return token.address
    }
    let splitCount = tokenAddress.count > 100 ? tokenAddress.count / 3 : 100
    let addressesTrucked = tokenAddress.chunked(into: splitCount)
    let provider = MoyaProvider<KrytalService>(plugins: [])
    var output: [TokenPrice] = []
    self.isLoadingExchangeTokenRates = true
    self.requestingChain = KNGeneralProvider.shared.currentChain
    let allChainQuote: [String] = (["btc", "usd"] + ChainType.getAllChain().map { $0.quoteToken().lowercased() }).unique
    let group = DispatchGroup()
    group.enter()
    provider.requestWithFilter(.getOverviewMarket(addresses: [], quotes: allChainQuote)) { result in
      if case .success(let resp) = result {
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(OverviewResponse.self, from: resp.data)
          let priceObj = data.data.map { item in
            return TokenPrice(address: item.address, quotes: item.quotes)
          }
          output.append(contentsOf: priceObj)
          print("[GetOverview][Supported][Success] ")
        } catch let error {
          print("[GetOverview][Supported][Error] \(error.localizedDescription)")
        }
      } else {
        print("[GetOverview][Supported][Error] ")
      }
      group.leave()
    }

    addressesTrucked.forEach { (element) in
      group.enter()
      provider.requestWithFilter(.getOverviewMarket(addresses: element, quotes: allChainQuote)) { result in
        if case .success(let resp) = result {
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(OverviewResponse.self, from: resp.data)
            let priceObj = data.data.map { item in
              return TokenPrice(address: item.address, quotes: item.quotes)
            }
            output.append(contentsOf: priceObj)
            print("[GetOverview][Success] ")
          } catch let error {
            print("[GetOverview][Error] \(error.localizedDescription)")
          }
        } else {
          print("[GetOverview][Error] ")
        }
        group.leave()
      }
    }
    group.notify(queue: .global()) {
      self.isLoadingExchangeTokenRates = false
      KNTrackerRateStorage.shared.updatePrices(output)
      DispatchQueue.main.async {
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      }
      tx.finish()
    }
  }
}

class KNRateHelper {
  static func displayRate(from rate: BigInt, decimals: Int) -> String {
    /*
     Displaying rate with at most 4 digits after leading zeros
     */
    if rate.isZero { return "0.0000" }
    var string = rate.string(decimals: decimals, minFractionDigits: decimals, maxFractionDigits: decimals)
    let separator = EtherNumberFormatter.full.decimalSeparator
    if let _ = string.firstIndex(of: separator[separator.startIndex]) {
      string += "0000"
    } else {
      return rate.string(decimals: decimals, minFractionDigits: min(decimals, 4), maxFractionDigits: min(decimals, 4))
    }
    var isZeroNumber = false
    if let range = string.range(of: separator)?.lowerBound {
      let numberString = string[..<range]
      if Int(numberString) == 0 {
        isZeroNumber = true
      }
    }
    var start = false
    var cnt = 0
    var separatorIndex = 0
    var index = string.startIndex
    for id in 0..<string.count {
      if string[index] == separator[separator.startIndex] {
        separatorIndex = id
        start = true
      } else if start {
        if !isZeroNumber && (id - separatorIndex) == 6 {
          let fractionDigit = cnt == 0 ? 4 : 6
          return rate.string(
            decimals: decimals,
            minFractionDigits: fractionDigit,
            maxFractionDigits: fractionDigit
          )
        }
        if cnt > 0 || string[index] != "0" { cnt += 1 }
        if cnt == 4 {
          return rate.string(
            decimals: decimals,
            minFractionDigits: id - separatorIndex,
            maxFractionDigits: id - separatorIndex
          )
        }
      }
      index = string.index(after: index)
    }
    if cnt == 0, let id = string.firstIndex(of: separator[separator.startIndex]) {
      index = string.index(id, offsetBy: 5)
      return String(string[..<index])
    }
    return string
  }

  static func displayRate(from rate: String, mainRuleDecimals: Int = 2, meaningNumber: Int = 4) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = mainRuleDecimals
    let mainRuleConvertedNumber = formatter.number(from: rate) ?? NSNumber(value: 0)
    guard mainRuleConvertedNumber.doubleValue < 0.1 else {
      return formatter.string(from: mainRuleConvertedNumber) ?? ""
    }

    var string = rate
    let separator = EtherNumberFormatter.full.decimalSeparator
    if let _ = string.firstIndex(of: separator[separator.startIndex]) { string = string + "0000" }
    var start = false
    var cnt = 0
    var index = string.startIndex
    for id in 0..<string.count {
      if string[index] == separator[separator.startIndex] {
        start = true
      } else if start {
        if cnt > 0 && string[index] == "0" {
          return string.substring(to: id)
        }
        if cnt > 0 || string[index] != "0" {
          cnt += 1
        }
        if cnt == meaningNumber { return string.substring(to: id + 1) }
      }
      index = string.index(after: index)
    }
    if cnt == 0, let id = string.firstIndex(of: separator[separator.startIndex]) {
      index = string.index(id, offsetBy: 5)
      return String(string[..<index])
    }
    return string
  }
}
