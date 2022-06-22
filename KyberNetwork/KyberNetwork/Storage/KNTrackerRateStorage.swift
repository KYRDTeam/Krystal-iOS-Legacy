// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import BigInt

class KNTrackerRateStorage {

  static var shared = KNTrackerRateStorage()
  private(set) var realm: Realm!
  private var allPrices: ThreadProtectedObject<[TokenPrice]> = .init(storageValue: [])
  private var chainAllPrices: [ChainType : [TokenPrice]]

  init() {
    self.allPrices.value = KNTrackerRateStorage.loadPricesFromLocalData()
    var chainAllPricesDic: [ChainType : [TokenPrice]] = [:]
    ChainType.getAllChain().forEach { chain in
      chainAllPricesDic[chain] = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: chain)
    }
    self.chainAllPrices = chainAllPricesDic
  }

  func reloadData() {
    self.allPrices.value = KNTrackerRateStorage.loadPricesFromLocalData()
    self.updateCacheRate(chain: KNGeneralProvider.shared.currentChain, rates: self.allPrices.value)
  }
  
  private func updateCacheRate(chain: ChainType, rates: [TokenPrice]) {
    self.chainAllPrices[chain] = rates
  }

  //MARK: new implementation
  static func loadPricesFromLocalData() -> [TokenPrice] {
    if KNEnvironment.default != .ropsten {
      return Storage.retrieve(KNEnvironment.default.envPrefix + Constants.coingeckoPricesStoreFileName, as: [TokenPrice].self) ?? []
    } else {
      return []
    }
  }
  
  func getAllPrices() -> [TokenPrice] {
    return self.allPrices.value
  }
  
  func getPriceWithAddress(_ address: String) -> TokenPrice? {
    return getAllPrices().first { (item) -> Bool in
      return item.address.lowercased() == address.lowercased()
    }
  }
  
  static func retrievePricesFromHardDisk(chainType: ChainType) -> [TokenPrice] {
    let allPrices = Storage.retrieve(chainType.getChainDBPath() + Constants.coingeckoPricesStoreFileName, as: [TokenPrice].self) ?? []
    return allPrices
  }

  private func getPricesFor(chainType: ChainType) -> [TokenPrice] {
    return self.chainAllPrices[chainType] ?? []
  }

  func getPriceWithAddress(_ address: String, chainType: ChainType) -> TokenPrice? {
    let allPrices = self.getPricesFor(chainType: chainType)
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
    default:
      return price.quote
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
        
        saved.quote = item.quote
        saved.quote24hVol = item.quote24hVol
        saved.quoteMarketCap = item.quoteMarketCap
        saved.quote24hChange = item.quote24hChange
      } else {
        self.allPrices.value.append(item)
      }
    }
    Storage.store(self.allPrices.value, as: KNEnvironment.default.envPrefix + Constants.coingeckoPricesStoreFileName)
  }
}
