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
  private var allLendingBalance: [LendingPlatformBalance] = []
  private var nftBalance: [NFTSection] = []
  private var customNftBalance: [NFTSection] = []
  private var distributionBalance: LendingDistributionBalance?
  private var wallet: Wallet?
  
  var allBalance: [TokenBalance] {
    return self.supportedTokenBalances
  }
  
  func getAllLendingBalances() -> [LendingPlatformBalance] {
//    if self.allLendingBalance.isEmpty, let unwrapped = self.wallet {
//      self.updateCurrentWallet(unwrapped)
//    }
    return self.allLendingBalance
  }
  
  func getDistributionBalance() -> LendingDistributionBalance? {
    return self.distributionBalance
  }

  func setBalances(_ balances: [TokenBalance]) {
    guard let unwrapped = self.wallet else {
      return
    }
    
    self.supportedTokenBalances = balances
    Storage.store(balances, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.balanceStoreFileName)
  }
  
  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet
    DispatchQueue.global(qos: .background).async {
      self.supportedTokenBalances = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.balanceStoreFileName, as: [TokenBalance].self) ?? []
      self.allLendingBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.lendingBalanceStoreFileName, as: [LendingPlatformBalance].self) ?? []
      self.distributionBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.lendingDistributionBalanceStoreFileName, as: LendingDistributionBalance.self)
      self.nftBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.nftBalanceStoreFileName, as: [NFTSection].self) ?? []
//      self.customNftBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.customNftBalanceStoreFileName, as: [NFTSection].self) ?? []
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
  
  func supportedTokenBalanceForAddress(_ address: String) -> TokenBalance? {
    let balance = self.supportedTokenBalances.first { (balance) -> Bool in
      return balance.address.lowercased() == address.lowercased()
    }
    return balance
  }

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

  func balanceETH() -> String {
    return self.balanceForAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")?.balance ?? ""
  }
  
  func balanceBNB() -> String {
    return self.balanceForAddress(Constants.bnbAddress)?.balance ?? ""
  }

  func getBalanceETHBigInt() -> BigInt {
    return BigInt(self.balanceETH()) ?? BigInt(0)
  }
  
  func getBalanceBNBBigInt() -> BigInt {
    return BigInt(self.balanceBNB()) ?? BigInt(0)
  }
  
  func getTotalAssetBalanceUSD(_ currency: CurrencyMode) -> BigInt {
    var total = BigInt(0)
    let tokens = KNSupportedTokenStorage.shared.allTokens
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
  
  func getTotalBalance(_ currency: CurrencyMode) -> BigInt {
    return self.getTotalAssetBalanceUSD(currency) + self.getTotalSupplyBalance(currency)
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
