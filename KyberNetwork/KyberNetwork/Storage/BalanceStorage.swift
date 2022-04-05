//
//  BalanceStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/21/21.
//

import Foundation
import BigInt

class BalanceStorage {
  static let shared = BalanceStorage()
  private var supportedTokenBalances: [TokenBalance] = []
  private var summaryChainModels: [KNSummaryChainModel] = []
  private var allLendingBalance: [LendingPlatformBalance] = []
  private var allLiquidityPool: [LiquidityPoolModel] = []
  private var nftBalance: [NFTSection] = []
  private var customNftBalance: [NFTSection] = []
  private var distributionBalance: LendingDistributionBalance?
  private var wallet: Wallet?
  
  private var ethTokenBalances: [TokenBalance] = []
  private var bscTokenBalances: [TokenBalance] = []
  private var polygonTokenBalances: [TokenBalance] = []
  private var avaxTokenBalances: [TokenBalance] = []
  private var cronosTokenBalances: [TokenBalance] = []
  private var fantomTokenBalances: [TokenBalance] = []
  private var arbitrumTokenBalances: [TokenBalance] = []
  private var auroraTokenBalances: [TokenBalance] = []

  var allBalance: [TokenBalance] {
    return self.supportedTokenBalances
  }
  
  func getAllLendingBalances() -> [LendingPlatformBalance] {
    return self.allLendingBalance
  }
  
  func getDistributionBalance() -> LendingDistributionBalance? {
    return self.distributionBalance
  }

  func setBalances(_ balances: [TokenBalance]) {
    guard let unwrapped = self.wallet else {
      return
    }
    
    self.setCacheForChain(chain: KNGeneralProvider.shared.currentChain, balances: balances)
    
    self.supportedTokenBalances = balances
    Storage.store(balances, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.balanceStoreFileName)
  }
  
  private func setCacheForChain(chain: ChainType, balances: [TokenBalance]) {
    switch chain {
    case .eth:
      self.ethTokenBalances = balances
    case .bsc:
      self.bscTokenBalances = balances
    case .polygon:
      self.polygonTokenBalances = balances
    case .avalanche:
      self.avaxTokenBalances = balances
    case .cronos:
      self.cronosTokenBalances = balances
    case .fantom:
      self.fantomTokenBalances = balances
    case .arbitrum:
      self.arbitrumTokenBalances = balances
    case .aurora:
      self.auroraTokenBalances = balances
    }
  }
  
  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet
    DispatchQueue.global(qos: .background).async {
      let walletAddress = wallet.address.description.lowercased()
      self.ethTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .eth)
      self.bscTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .bsc)
      self.polygonTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .polygon)
      self.avaxTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .avalanche)
      self.cronosTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .cronos)
      self.fantomTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .fantom)
      self.arbitrumTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .arbitrum)
      self.auroraTokenBalances = self.retrieveBalancesInHardDisk(address: walletAddress, chainType: .aurora)
      
      self.supportedTokenBalances = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.balanceStoreFileName, as: [TokenBalance].self) ?? []
      self.allLendingBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.lendingBalanceStoreFileName, as: [LendingPlatformBalance].self) ?? []
      self.allLiquidityPool = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.liquidityPoolStoreFileName, as: [LiquidityPoolModel].self) ?? []
      self.distributionBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.lendingDistributionBalanceStoreFileName, as: LendingDistributionBalance.self)
      self.nftBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.nftBalanceStoreFileName, as: [NFTSection].self) ?? []
      self.customNftBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.customNftBalanceStoreFileName, as: [NFTSection].self) ?? []
      self.summaryChainModels = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.summaryChainStoreFileName, as: [KNSummaryChainModel].self) ?? []

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
  
  private func retrieveBalancesInHardDisk(address: String, chainType: ChainType) -> [TokenBalance] {
    let allBalance = Storage.retrieve(self.getChainDBPath(chainType: chainType) + address + Constants.balanceStoreFileName, as: [TokenBalance].self) ?? []
    return allBalance
  }
  
  private func getBalancesFor(chain: ChainType) -> [TokenBalance] {
    switch chain {
    case .eth:
      return self.ethTokenBalances
    case .bsc:
      return self.bscTokenBalances
    case .polygon:
      return self.polygonTokenBalances
    case .avalanche:
      return self.avaxTokenBalances
    case .cronos:
      return self.cronosTokenBalances
    case .fantom:
      return self.fantomTokenBalances
    case .arbitrum:
      return self.arbitrumTokenBalances
    case .aurora:
      return self.auroraTokenBalances
    }
  }
  
  func balanceForAddressInChain(_ address: String, chainType: ChainType) -> TokenBalance? {
    guard self.wallet != nil else {
      return nil
    }

    let allBalance = self.getBalancesFor(chain: chainType)
    let balance = allBalance.first { (balance) -> Bool in
      return balance.address.lowercased() == address.lowercased()
    }
    return balance
  }
  
  func getChainDBPath(chainType: ChainType) -> String {
    return chainType.getChainDBPath()
  }

//  func supportedTokenBalanceForAddress(_ address: String) -> TokenBalance? {
//    let balance = self.supportedTokenBalances.first { (balance) -> Bool in
//      return balance.address.lowercased() == address.lowercased()
//    }
//    return balance
//  }

  func setLendingBalances(_ balances: [LendingPlatformBalance]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.allLendingBalance = balances
    Storage.store(balances, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.lendingBalanceStoreFileName)
  }

  func setLendingDistributionBalance(_ balance: LendingDistributionBalance) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.distributionBalance = balance
    Storage.store(balance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.lendingDistributionBalanceStoreFileName)
  }
  
  func setLiquidityPools(_ liquidityPools: [LiquidityPoolModel]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.allLiquidityPool = liquidityPools
    Storage.store(liquidityPools, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.liquidityPoolStoreFileName)
  }

  func saveSummaryChainModels(_ summaryChainsModels: [KNSummaryChainModel]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.summaryChainModels = summaryChainsModels
    Storage.store(summaryChainsModels, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.summaryChainStoreFileName)
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
    let lendingBalances = BalanceStorage.shared.getAllLendingBalances()
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
    let allBalances: [LendingPlatformBalance] = self.getAllLendingBalances()

    allBalances.forEach { (item) in
      item.balances.forEach { (balanceItem) in
        let balance = BigInt(balanceItem.supplyBalance) ?? BigInt(0)
        let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: balanceItem.address, currency: currency)
        let value = balance * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(balanceItem.decimals)
        total += value
      }
    }
    
    if let otherData = BalanceStorage.shared.getDistributionBalance() {
      let balance = BigInt(otherData.unclaimed) ?? BigInt(0)
      let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: otherData.address, currency: currency)
      let value = balance * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(otherData.decimal)
      total += value
    }

    return total
  }

  func getSupplyBalances() -> ([String], [String : [Any]]) {
    var sectionKeys: [String] = []
    var balanceDict: [String : [Any]] = [:]
    let allBalances: [LendingPlatformBalance] = BalanceStorage.shared.getAllLendingBalances()
    allBalances.forEach { (item) in
      if !item.balances.isEmpty {
        balanceDict[item.name] = item.balances
        sectionKeys.append(item.name)
      }
    }
    if let otherData = BalanceStorage.shared.getDistributionBalance() {
      balanceDict["OTHER"] = [otherData]
      sectionKeys.append("OTHER")
    }
    
    return (sectionKeys, balanceDict)
  }
  
  func getSummaryChainModels() -> [KNSummaryChainModel] {
    return self.summaryChainModels
  }

  func getLiquidityPools(currency: CurrencyMode) -> ([String], [String: [Any]]) {
    var poolDict: [String: [Any]] = [:]
    var allProject: [String] = []

    self.allLiquidityPool.forEach { poolModel in
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
      self.allLiquidityPool.forEach { poolModel in
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
    return self.nftBalance + self.customNftBalance
  }
  
  func setNFTBalance(_ balance: [NFTSection]) {
    guard let unwrapped = self.wallet else {
      return
    }
    let allSectionAddress = self.nftBalance.map { item in
      return item.collectibleAddress.lowercased()
    }
    let customSectionAddress = self.customNftBalance.map { item in
      return item.collectibleAddress.lowercased()
    }
    let duplicateAddress = customSectionAddress.filter { item in
      return allSectionAddress.contains(item)
    }

    if !duplicateAddress.isEmpty {
      duplicateAddress.forEach { item in
        if let idx = customSectionAddress.firstIndex(of: item) {
          self.customNftBalance.remove(at: idx)
        }
      }
      Storage.store(self.customNftBalance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.nftBalanceStoreFileName)
    }

    self.nftBalance = balance
    Storage.store(self.nftBalance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.nftBalanceStoreFileName)
  }
  
  func getCustomNFT() -> [NFTSection] {
    return self.customNftBalance
  }
  
  func setCustomNFT(_ balance: NFTSection) -> Bool {
    guard let unwrapped = self.wallet else {
      return false
    }
    
    if self.nftBalance.firstIndex { item in
      return item.collectibleAddress.lowercased() == balance.collectibleAddress.lowercased()
    } != nil {
      return false
    }
    
    if let duplicateSectionIdx = self.customNftBalance.firstIndex { item in
      return item.collectibleAddress.lowercased() == balance.collectibleAddress.lowercased()
    } {
      let currentIDs = self.customNftBalance[duplicateSectionIdx].items.map { item in
        return item.tokenID
      }
      if let newItem = balance.items.first, !currentIDs.contains(newItem.tokenID) {
        self.customNftBalance[duplicateSectionIdx].items.append(newItem)
        
        Storage.store(self.customNftBalance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.customNftBalanceStoreFileName)
      }
      return true
    } else {
      self.customNftBalance.append(balance)
      Storage.store(self.customNftBalance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.customNftBalanceStoreFileName)
      return true
    }
  }

  func removeCustomNFT(categoryAddress: String, itemID: String) {
    guard let unwrapped = self.wallet else {
      return
    }
    if var category = self.customNftBalance.first(where: { item in
      return item.collectibleAddress.lowercased() == categoryAddress.lowercased()
    }) {
      if let index = category.items.firstIndex(where: { nftItem in
        return nftItem.tokenID == itemID
      }) {
        category.items.remove(at: index)
        if category.items.isEmpty {
          if let sectionIndex = self.customNftBalance.firstIndex(where: { sectionItem in
            return sectionItem.collectibleAddress.lowercased() == category.collectibleAddress.lowercased()
          }) {
            self.customNftBalance.remove(at: sectionIndex)
          }
        }
        Storage.store(self.customNftBalance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.customNftBalanceStoreFileName)
      }
    }
  }
  
  func updateCustomNFTBalance(categoryAddress: String, itemID: String, balance: String) {
    if let category = self.customNftBalance.first(where: { item in
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
    guard let unwrapped = self.wallet else {
      return
    }
    Storage.store(self.customNftBalance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.customNftBalanceStoreFileName)
  }
  
  func getAllFavedItems() -> [(NFTItem, NFTSection)] {
    var result: [(NFTItem, NFTSection)] = []
    
    self.getAllNFTBalance().forEach { section in
      section.items.forEach { item in
        if item.favorite {
          result.append((item, section))
        }
      }
    }
    return result
  }
}
