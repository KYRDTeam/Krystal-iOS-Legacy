// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNTrackerRateStorage {

  static var shared = KNTrackerRateStorage()
  private(set) var realm: Realm!
  private var allPrices: [TokenPrice]

  init() {
    self.allPrices = KNTrackerRateStorage.loadPricesFromLocalData()
  }

  func reloadData() {
    self.allPrices = KNTrackerRateStorage.loadPricesFromLocalData()
  }

  //MARK: new implementation
  static func loadPricesFromLocalData() -> [TokenPrice] {
    if KNEnvironment.default != .ropsten {
      return Storage.retrieve(KNEnvironment.default.envPrefix + Constants.coingeckoPricesStoreFileName, as: [TokenPrice].self) ?? []
    } else {
//      if let json = KNJSONLoaderUtil.jsonDataFromFile(with: "tokens_price") as? [String: JSONDictionary] {
//        var result: [TokenPrice] = []
//        json.keys.forEach { (key) in
//          var dict = json[key]
//          dict?["address"] = key
//          if let notNil = dict {
//            let price = TokenPrice(dictionary: notNil)
//            result.append(price)
//          }
//        }
//        return result
//
//      } else {
//        return []
//      }
      //TODO: create new default price
      return []
    }
  }
  
  func getAllPrices() -> [TokenPrice] {
    return self.allPrices
  }
  
  func getPriceWithAddress(_ address: String) -> TokenPrice? {
    return self.allPrices.first { (item) -> Bool in
      return item.address.lowercased() == address.lowercased()
    }
  }
  
  func getPriceWithAddress(_ address: String, chainType: ChainType) -> TokenPrice? {
    let allPrices = Storage.retrieve(self.getChainDBPath(chainType: chainType) + Constants.coingeckoPricesStoreFileName, as: [TokenPrice].self) ?? []
    return allPrices.first { (item) -> Bool in
      return item.address.lowercased() == address.lowercased()
    }
  }
  
  func getChainDBPath(chainType: ChainType) -> String {
    return chainType.getChainDBPath()
  }
  
  func getLastPriceWith(address: String, currency: CurrencyMode) -> Double {
    guard let price = self.getPriceWithAddress(address) else {
      return 0.0
    }
    switch currency {
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

  func getETHPrice() -> TokenPrice? {
    return KNGeneralProvider.shared.quoteTokenPrice
  }
  
  func updatePrices(_ prices: [TokenPrice]) {
    prices.forEach { (item) in
      if let saved = self.getPriceWithAddress(item.address) {
        saved.eth = item.eth
        saved.eth24hVol = item.eth24hVol
        saved.ethMarketCap = item.ethMarketCap
        saved.eth24hChange = item.eth24hChange
        
        saved.usd = item.usd
        saved.usd24hVol = item.usd24hVol
        saved.usdMarketCap = item.usdMarketCap
        saved.usd24hChange = item.usd24hChange
        
        saved.btc = item.btc
        saved.btc24hVol = item.btc24hVol
        saved.btcMarketCap = item.btcMarketCap
        saved.btc24hChange = item.btc24hChange
        
        saved.bnb = item.bnb
        saved.bnb24hVol = item.bnb24hVol
        saved.bnbMarketCap = item.bnbMarketCap
        saved.bnb24hChange = item.bnb24hChange
        
        saved.matic = item.matic
        saved.matic24hVol = item.matic24hVol
        saved.maticMarketCap = item.maticMarketCap
        saved.matic24hChange = item.matic24hChange
        
        saved.cro = item.cro
        saved.cro24hVol = item.cro24hVol
        saved.croMarketCap = item.croMarketCap
        saved.cro24hChange = item.cro24hChange
        
        saved.ftm = item.ftm
        saved.ftm24hVol = item.ftm24hVol
        saved.ftmMarketCap = item.ftmMarketCap
        saved.ftm24hChange = item.ftm24hChange
      } else {
        self.allPrices.append(item)
      }
    }
    Storage.store(self.allPrices, as: KNEnvironment.default.envPrefix + Constants.coingeckoPricesStoreFileName)
  }
}

