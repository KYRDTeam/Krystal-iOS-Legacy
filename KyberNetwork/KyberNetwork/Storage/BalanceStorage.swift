//
//  BalanceStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/21/21.
//

import Foundation
import BigInt
import KrystalWallets


struct SectionKeyType: Hashable {
  let key: String
  let chain: ChainType?
  
  static func == (lhs: SectionKeyType, rhs: SectionKeyType) -> Bool {
    return (lhs.key == rhs.key) && (lhs.chain == rhs.chain)
  }
  
  func toString() -> String {
    if let unwrap = self.chain {
      return "\(key)###\(unwrap.getChainId())"
    } else {
      return "\(key)"
    }
  }
}

class BalanceStorage {
  static let shared = BalanceStorage()
  private var supportedTokenBalances: ThreadProtectedObject<[TokenBalance]> = .init(storageValue: [])
  private var summaryChainModels: ThreadProtectedObject<[KNSummaryChainModel]> = .init(storageValue: [])
  private var allLendingBalance: ThreadProtectedObject<[LendingPlatformBalance]> = .init(storageValue: [])
  private var allLiquidityPool: ThreadProtectedObject<[LiquidityPoolModel]> = .init(storageValue: [])
  private var nftBalance: ThreadProtectedObject<[NFTSection]> = .init(storageValue: [])
  private var customNftBalance: ThreadProtectedObject<[NFTSection]> = .init(storageValue: [])
  private var distributionBalance: [LendingDistributionBalance] = []
  private var address: KAddress?
  private var chainTokenBalances: [ChainType: [TokenBalance]] = [:]
  
  var allBalance: [TokenBalance] {
    return self.supportedTokenBalances.value
  }
  
  func getAllLendingBalances(_ chain: ChainType) -> [LendingPlatformBalance] {
    if chain == .all {
      return self.allLendingBalance.value
    } else {
      return self.allLendingBalance.value.filter { e in
        return e.chainType == chain
      }
    }
  }
  
  func getDistributionBalance(_ chain: ChainType) -> [LendingDistributionBalance] {
    if chain == .all {
      return self.distributionBalance
    } else {
      return self.distributionBalance.filter { e in
        return e.chainType == chain
      }
    }
  }

  func setBalances(_ balances: [TokenBalance]) {
    guard let unwrapped = self.address else {
      return
    }
    
    self.setCacheForChain(chain: KNGeneralProvider.shared.currentChain, balances: balances)
    self.supportedTokenBalances.value = balances
    Storage.store(balances, as: KNEnvironment.default.envPrefix + unwrapped.addressString + Constants.balanceStoreFileName)
  }
  
  func setCacheForChain(chain: ChainType, balances: [TokenBalance]) {
    self.chainTokenBalances[chain] = balances
  }
  
  func updateCurrentWallet(_ address: KAddress) {
    self.address = address
    let addressString = address.addressString
    DispatchQueue.global(qos: .background).async {
      ChainType.getAllChain().forEach { chain in
        self.chainTokenBalances[chain] = self.retrieveBalancesInHardDisk(address: addressString, chainType: chain)
      }
      self.supportedTokenBalances.value = Storage.retrieve(KNEnvironment.default.envPrefix + addressString + Constants.balanceStoreFileName, as: [TokenBalance].self) ?? []
      self.allLendingBalance.value = Storage.retrieve(addressString + Constants.lendingBalanceStoreFileName, as: [LendingPlatformBalance].self) ?? []
      self.allLiquidityPool.value = Storage.retrieve(KNEnvironment.default.envPrefix + addressString + Constants.liquidityPoolStoreFileName, as: [LiquidityPoolModel].self) ?? []
      self.distributionBalance = Storage.retrieve(addressString + Constants.lendingDistributionBalanceStoreFileName, as: [LendingDistributionBalance].self) ?? []
      self.nftBalance.value = Storage.retrieve(addressString + Constants.nftBalanceStoreFileName, as: [NFTSection].self) ?? []
      self.customNftBalance.value = Storage.retrieve(addressString + Constants.customNftBalanceStoreFileName, as: [NFTSection].self) ?? []
      self.summaryChainModels.value = Storage.retrieve(KNEnvironment.default.envPrefix + addressString + Constants.summaryChainStoreFileName, as: [KNSummaryChainModel].self) ?? []

      DispatchQueue.main.async {
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      }
    }
  }

  func balanceForAddress(_ address: String) -> TokenBalance? {
    let balance = self.allBalance.first { (balance) -> Bool in
      return balance.address.lowercased() == address.lowercased()
    }
    return balance
  }
  
  func updateBalanceForAddress(_ address: String, value: BigInt) {
    guard let unwrapped = self.address else {
      return
    }
    let balance = self.allBalance.first { (balance) -> Bool in
      return balance.address == address
    }
    balance?.balance = String(value)
    Storage.store(self.allBalance, as: KNEnvironment.default.envPrefix + unwrapped.addressString + Constants.balanceStoreFileName)
  }
  
  private func retrieveBalancesInHardDisk(address: String, chainType: ChainType) -> [TokenBalance] {
    let allBalance = Storage.retrieve(self.getChainDBPath(chainType: chainType) + address + Constants.balanceStoreFileName, as: [TokenBalance].self) ?? []
    return allBalance
  }
  
  private func getBalancesFor(chain: ChainType) -> [TokenBalance] {
    return self.chainTokenBalances[chain] ?? []
  }
  
  func balanceForAddressInChain(_ address: String, chainType: ChainType) -> TokenBalance? {
    let allBalance = self.getBalancesFor(chain: chainType)
    let balance = allBalance.first { (balance) -> Bool in
      return balance.address == address
    }
    return balance
  }
  
  func getChainDBPath(chainType: ChainType) -> String {
    return chainType.getChainDBPath()
  }

  func setLendingBalances(_ balances: [LendingPlatformBalance]) {
    guard let unwrapped = self.address else {
      return
    }
    self.allLendingBalance.value = balances
    Storage.store(balances, as: unwrapped.addressString + Constants.lendingBalanceStoreFileName)
  }

  func setLendingDistributionBalance(_ balance: [LendingDistributionBalance]) {
    guard let unwrapped = self.address else {
      return
    }
    self.distributionBalance = balance
    Storage.store(balance, as: unwrapped.addressString + Constants.lendingDistributionBalanceStoreFileName)
  }
  
  func setLiquidityPools(_ liquidityPools: [LiquidityPoolModel]) {
    guard let unwrapped = self.address else {
      return
    }
    self.allLiquidityPool.value = liquidityPools
    Storage.store(liquidityPools, as: KNEnvironment.default.envPrefix + unwrapped.addressString + Constants.liquidityPoolStoreFileName)
  }

  func saveSummaryChainModels(_ summaryChainsModels: [KNSummaryChainModel]) {
    guard let unwrapped = self.address else {
      return
    }
    self.summaryChainModels.value = summaryChainsModels
    Storage.store(summaryChainsModels, as: KNEnvironment.default.envPrefix + unwrapped.addressString + Constants.summaryChainStoreFileName)
  }

  func balanceETH() -> String {
    return self.balanceForAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")?.balance ?? ""
  }
  
  func balanceBNB() -> String {
    return self.balanceForAddress(AllChains.bscMainnetPRC.quoteTokenAddress)?.balance ?? ""
  }

  func getBalanceETHBigInt() -> BigInt {
    return BigInt(self.balanceETH()) ?? BigInt(0)
  }
  
  func getBalanceBNBBigInt() -> BigInt {
    return BigInt(self.balanceBNB()) ?? BigInt(0)
  }

  func getTotalAssetBalanceUSD(_ currency: CurrencyMode) -> BigInt {
    var total = BigInt(0)
    let tokens = KNSupportedTokenStorage.shared.allActiveTokens
    let lendingBalances = BalanceStorage.shared.getAllLendingBalances(KNGeneralProvider.shared.currentChain)
    var lendingSymbols: [String] = []
    lendingBalances.forEach { (lendingPlatform) in
      lendingPlatform.balances.forEach { (balance) in
        lendingSymbols.append(balance.interestBearingTokenSymbol.lowercased())
      }
    }

    tokens.forEach { (token) in
      guard token.getBalanceBigInt() > BigInt(0), !lendingSymbols.contains(token.symbol.lowercased()) else {
        return
      }

      let balance = token.getBalanceBigInt()
      let rateBigInt = BigInt(token.getTokenLastPrice(currency) * pow(10.0, 18.0))
      let valueBigInt = balance * rateBigInt / BigInt(10).power(token.decimals)
      total += valueBigInt
    }
    return total
  }
  
  func getTotalLiquidityPoolUSD(_ currency: CurrencyMode) -> BigInt {
    let liquidityPoolData = self.getLiquidityPools(currency: currency)
    let data = liquidityPoolData.1
    var total = 0.0
    
    let keysArray = liquidityPoolData.0
    
    keysArray.forEach { (key) in
      var totalSection = 0.0
      data[key.lowercased()]?.forEach({ (item) in
        if let poolPairToken = item as? [LPTokenModel] {
          poolPairToken.forEach { token in
            //add total value of each token in current pair
            totalSection += token.getTokenValue(currency)
          }
        }
      })
      total += totalSection
    }
    
    return BigInt(total * pow(10.0, 18.0))
  }

  func getTotalSupplyBalance(_ currency: CurrencyMode) -> BigInt {
    var total = BigInt(0)
    let allBalances: [LendingPlatformBalance] = self.getAllLendingBalances(KNGeneralProvider.shared.currentChain)

    allBalances.forEach { (item) in
      item.balances.forEach { (balanceItem) in
        let balance = BigInt(balanceItem.supplyBalance) ?? BigInt(0)
        let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: balanceItem.address, currency: currency)
        let value = balance * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(balanceItem.decimals)
        total += value
      }
    }
    
    BalanceStorage.shared.getDistributionBalance(KNGeneralProvider.shared.currentChain).forEach { e in
      let balance = BigInt(e.unclaimed) ?? BigInt(0)
      let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: e.address, currency: currency)
      let value = balance * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(e.decimal)
      total += value
    }

    return total
  }

  func getSupplyBalances(_ chain: ChainType) -> ([SectionKeyType], [String: [Any]]) {
    var sectionKeys: [SectionKeyType] = []
    var balanceDict: [String: [Any]] = [:]
    let allBalances: [LendingPlatformBalance] = BalanceStorage.shared.getAllLendingBalances(chain)

    allBalances.forEach { (item) in
      if !item.balances.isEmpty {
        let key = SectionKeyType(key: item.name, chain: item.chainType)
        balanceDict[key.toString()] = item.balances
        sectionKeys.append(key)
      }
    }
    
    balanceDict["OTHER"] = BalanceStorage.shared.getDistributionBalance(chain)
    sectionKeys.append(SectionKeyType(key: "OTHER", chain: nil))
    
    return (sectionKeys, balanceDict)
  }
  
  func getSummaryChainModels() -> [KNSummaryChainModel] {
    return self.summaryChainModels.value
  }

  func getLiquidityPools(currency: CurrencyMode) -> ([String], [String: [Any]]) {
    var poolDict: [String: [Any]] = [:]
    var allProject: [String] = []

    self.allLiquidityPool.value.forEach { poolModel in
      let element = allProject.first { project in
        project.lowercased() == poolModel.project.lowercased()
      }
      
      if element == nil {
        // only add project if `allProject` doesn't contain it < with case sensitive checked >
        allProject.append(poolModel.project)
      }

    }

    allProject.forEach { project in
      var currentPoolPairTokens: [[LPTokenModel]] = []
      // add all pair of current pool project
      self.allLiquidityPool.value.forEach { poolModel in
        if poolModel.project.lowercased() == project.lowercased() {
          currentPoolPairTokens.append(poolModel.lpTokenArray)
        }
      }
      // sort all pair in current pool project first by value then by balance
      currentPoolPairTokens = currentPoolPairTokens.sorted { pair1, pair2 in
        var totalPair1 = 0.0
        var pair1Balance = 0.0
        pair1.forEach { lpmodel in
          totalPair1 += lpmodel.getTokenValue(currency)
          pair1Balance += Double(lpmodel.getBalanceBigInt().string(decimals: lpmodel.token.decimals, minFractionDigits: 0, maxFractionDigits: min(lpmodel.token.decimals, 5))) ?? 0
        }
        
        var totalPair2 = 0.0
        var pair2Balance = 0.0
        pair2.forEach { lpmodel in
          totalPair2 += lpmodel.getTokenValue(currency)
          pair2Balance += Double(lpmodel.getBalanceBigInt().string(decimals: lpmodel.token.decimals, minFractionDigits: 0, maxFractionDigits: min(lpmodel.token.decimals, 5))) ?? 0
        }
        
        if totalPair1 != totalPair2 {
          return totalPair1 > totalPair2
        } else {
          return pair1Balance > pair2Balance
        }
        
      }
      // add sorted list pair tokens with current pool project key
      poolDict[project.lowercased()] = currentPoolPairTokens
    }

    allProject = allProject.sorted { key1, key2 in
      var totalSection1 = 0.0
      poolDict[key1.lowercased()]?.forEach({ (item) in
        if let poolPairToken = item as? [LPTokenModel] {
          poolPairToken.forEach { token in
            //add total value of each token in current pair
            totalSection1 += token.getTokenValue(currency)
          }
        }
      })
      
      var totalSection2 = 0.0
      poolDict[key2.lowercased()]?.forEach({ (item) in
        if let poolPairToken = item as? [LPTokenModel] {
          poolPairToken.forEach { token in
            //add total value of each token in current pair
            totalSection2 += token.getTokenValue(currency)
          }
        }
      })

      return totalSection1 > totalSection2
    }

    return (allProject, poolDict)
  }
  
  func getTotalBalance(_ currency: CurrencyMode) -> BigInt {
    return self.getTotalAssetBalanceUSD(currency) + self.getTotalSupplyBalance(currency) + self.getTotalLiquidityPoolUSD(currency)
  }
  
  func getAllNFTBalance() -> [NFTSection] {
    return self.nftBalance.value + self.customNftBalance.value
  }
  
  func getNFTBalanceForChain(_ chain: ChainType) -> [NFTSection] {
    guard chain != .all else {
      return self.getAllNFTBalance()
    }
    return self.getAllNFTBalance().filter { e in
      return e.chainType == chain
    }
  }
  
  func setNFTBalance(_ balance: [NFTSection]) {
    guard let unwrapped = self.address else {
      return
    }
    let allSectionAddress = self.nftBalance.value.map { item in
      return item.collectibleAddress.lowercased()
    }
    let customSectionAddress = self.customNftBalance.value.map { item in
      return item.collectibleAddress.lowercased()
    }
    let duplicateAddress = customSectionAddress.filter { item in
      return allSectionAddress.contains(item)
    }

    if !duplicateAddress.isEmpty {
      duplicateAddress.forEach { item in
        if let idx = customSectionAddress.firstIndex(of: item) {
          self.customNftBalance.value.remove(at: idx)
        }
      }
      Storage.store(self.customNftBalance.value, as: unwrapped.addressString + Constants.nftBalanceStoreFileName)
    }

    self.nftBalance.value = balance
    Storage.store(self.nftBalance.value, as: unwrapped.addressString + Constants.nftBalanceStoreFileName)
  }
  
  func getCustomNFT() -> [NFTSection] {
    return self.customNftBalance.value
  }
  
  func setCustomNFT(_ balance: NFTSection) -> Bool {
    guard let unwrapped = self.address else {
      return false
    }
    
    if self.nftBalance.value.firstIndex { item in
      return item.collectibleAddress.lowercased() == balance.collectibleAddress.lowercased()
    } != nil {
      return false
    }
    
    if let duplicateSectionIdx = self.customNftBalance.value.firstIndex { item in
      return item.collectibleAddress.lowercased() == balance.collectibleAddress.lowercased()
    } {
      let currentIDs = self.customNftBalance.value[duplicateSectionIdx].items.map { item in
        return item.tokenID
      }
      if let newItem = balance.items.first, !currentIDs.contains(newItem.tokenID) {
        self.customNftBalance.value[duplicateSectionIdx].items.append(newItem)
        
        Storage.store(self.customNftBalance.value, as: unwrapped.addressString + Constants.customNftBalanceStoreFileName)
      }
      return true
    } else {
      self.customNftBalance.value.append(balance)
      Storage.store(self.customNftBalance.value, as: unwrapped.addressString + Constants.customNftBalanceStoreFileName)
      return true
    }
  }

  func removeCustomNFT(categoryAddress: String, itemID: String) {
    guard let unwrapped = self.address else {
      return
    }
    if var category = self.customNftBalance.value.first(where: { item in
      return item.collectibleAddress.lowercased() == categoryAddress.lowercased()
    }) {
      if let index = category.items.firstIndex(where: { nftItem in
        return nftItem.tokenID == itemID
      }) {
        category.items.remove(at: index)
        if category.items.isEmpty {
          if let sectionIndex = self.customNftBalance.value.firstIndex(where: { sectionItem in
            return sectionItem.collectibleAddress.lowercased() == category.collectibleAddress.lowercased()
          }) {
            self.customNftBalance.value.remove(at: sectionIndex)
          }
        }
        Storage.store(self.customNftBalance.value, as: unwrapped.addressString + Constants.customNftBalanceStoreFileName)
      }
    }
  }
  
  func updateCustomNFTBalance(categoryAddress: String, itemID: String, balance: String) {
    if let category = self.customNftBalance.value.first(where: { item in
      return item.collectibleAddress.lowercased() == categoryAddress.lowercased()
    }) {
      if let nftItem = category.items.first(where: { nftItem in
        return nftItem.tokenID == itemID
      }) {
        if let balanceInt = Int(balance), balanceInt != 0 {
          nftItem.tokenBalance = balance
        } else {
          self.removeCustomNFT(categoryAddress: categoryAddress, itemID: itemID)
        }
        
      }
    }
  }
  
  func saveCustomNFT() {
    guard let unwrapped = self.address else {
      return
    }
    Storage.store(self.customNftBalance.value, as: unwrapped.addressString + Constants.customNftBalanceStoreFileName)
  }
  
  func getAllFavedItems(_ chain: ChainType) -> [(NFTItem, NFTSection)] {
    var result: [(NFTItem, NFTSection)] = []
    
    self.getAllNFTBalance().forEach { section in
      section.items.forEach { item in
        if item.favorite {
          if chain == .all {
            result.append((item, section))
          } else {
            if section.chainType == chain {
              result.append((item, section))
            }
          }
        }
      }
    }
    return result
  }
}
