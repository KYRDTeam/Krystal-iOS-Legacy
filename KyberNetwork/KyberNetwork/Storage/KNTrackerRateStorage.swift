// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNTrackerRateStorage {

  static var shared = KNTrackerRateStorage()
  private(set) var realm: Realm!
  private var allPrices: [TokenPrice]
  
  private var ethAllPrices: [TokenPrice]
  private var bscAllPrices: [TokenPrice]
  private var polygonAllPrices: [TokenPrice]
  private var avalancheAllPrices: [TokenPrice]
  private var cronosAllPrices: [TokenPrice]
  private var fantomAllPrices: [TokenPrice]
  private var arbitrumAllPrices: [TokenPrice]
  private var auroraAllPrices: [TokenPrice]

  init() {
    self.allPrices = KNTrackerRateStorage.loadPricesFromLocalData()
    
    self.ethAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .eth)
    self.bscAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .bsc)
    self.polygonAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .polygon)
    self.avalancheAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .avalanche)
    self.cronosAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .cronos)
    self.fantomAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .fantom)
    self.arbitrumAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .arbitrum)
    self.auroraAllPrices = KNTrackerRateStorage.retrievePricesFromHardDisk(chainType: .aurora)
  }

  func reloadData() {
    self.allPrices = KNTrackerRateStorage.loadPricesFromLocalData()
    self.updateCacheRate(chain: KNGeneralProvider.shared.currentChain, rates: self.allPrices)
  }
  
  private func updateCacheRate(chain: ChainType, rates: [TokenPrice]) {
    switch chain {
    case .eth:
      self.ethAllPrices = rates
    case .bsc:
      self.bscAllPrices = rates
    case .polygon:
      self.polygonAllPrices = rates
    case .avalanche:
      self.avalancheAllPrices = rates
    case .cronos:
      self.cronosAllPrices = rates
    case .fantom:
      self.fantomAllPrices = rates
    case .arbitrum:
      self.arbitrumAllPrices = rates
    case .aurora:
      self.auroraAllPrices = rates
    }
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
    return self.allPrices
  }
  
  func getPriceWithAddress(_ address: String) -> TokenPrice? {
    return self.allPrices.first { (item) -> Bool in
      return item.address.lowercased() == address.lowercased()
    }
  }
  
  static func retrievePricesFromHardDisk(chainType: ChainType) -> [TokenPrice] {
    let allPrices = Storage.retrieve(chainType.getChainDBPath() + Constants.coingeckoPricesStoreFileName, as: [TokenPrice].self) ?? []
    return allPrices
  }

  private func getPricesFor(chainType: ChainType) -> [TokenPrice] {
    switch chainType {
    case .eth:
      return self.ethAllPrices
    case .bsc:
      return self.bscAllPrices
    case .polygon:
      return self.polygonAllPrices
    case .avalanche:
      return self.avalancheAllPrices
    case .cronos:
      return self.cronosAllPrices
    case .fantom:
      return self.fantomAllPrices
    case .arbitrum:
      return self.arbitrumAllPrices
    case .aurora:
      return self.auroraAllPrices
    }
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
        self.allPrices.append(item)
      }
    }
    Storage.store(self.allPrices, as: KNEnvironment.default.envPrefix + Constants.coingeckoPricesStoreFileName)
  }
}
