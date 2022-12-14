//
//  OverviewMainViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 13/10/2021.
//
import BigInt
import UIKit

enum OverviewMainViewEvent {
  case send(recipientAddress: String?)
  case receive
  case search
  case notifications
  case changeMode(current: ViewMode)
  case walletConfig
  case select(token: Token, chainId: Int? = nil)
  case selectListWallet
  case withdrawBalance(platform: String, balance: LendingBalance)
  case claim(balance: LendingDistributionBalance)
  case depositMore
  case changeRightMode(current: ViewMode)
  case addNFT
  case openNFTDetail(item: NFTItem, category: NFTSection)
  case didAppear
  case pullToRefreshed(current: ViewMode, overviewMode: OverviewMode)
  case buyCrypto
  case addNewWallet
  case addChainWallet(chain: ChainType)
  case scannedWalletConnect(url: String)
  case selectAllChain
  case importWallet(privateKey: String, chain: ChainType)
  case openPromotion(code: String)
  case getBadgeNotification
}

enum OverviewMode {
  case overview
  case summary
}

enum ViewMode: Equatable, Codable {
  case market(rightMode: RightMode)
  case asset(rightMode: RightMode)
  case showLiquidityPool
  case supply
  case favourite(rightMode: RightMode)
  case nft
  
  public static func == (lhs: ViewMode, rhs: ViewMode) -> Bool {
    switch (lhs, rhs) {
    case ( .market, .market):
      return true
    case ( .asset, .asset):
      return true
    case ( .showLiquidityPool, .showLiquidityPool):
      return true
    case ( .supply, .supply):
      return true
    case ( .favourite, .favourite):
      return true
    case ( .nft, .nft):
      return true
    default:
      return false
    }
  }
  
  enum CodingKeys: CodingKey {
    case market, asset, showLiquidityPool, supply, favourite, nft
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .market(rightMode: let rightMode):
      try container.encode(rightMode, forKey: .market)
    case .asset(rightMode: let rightMode):
      try container.encode(rightMode, forKey: .asset)
    case .supply:
      try container.encode(true, forKey: .supply)
    case .favourite(rightMode: let rightMode):
      try container.encode(rightMode, forKey: .favourite)
    case .nft:
      try container.encode(true, forKey: .nft)
    case .showLiquidityPool:
      try container.encode(true, forKey: .showLiquidityPool)
    }
  }
  
  func toString() -> String {
    switch self {
    case .market:
      return "market"
    case .asset:
      return "asset"
    case .showLiquidityPool:
      return "liquidity_pool"
    case .supply:
      return "supply"
    case .favourite:
      return "favourite"
    case .nft:
      return "nft"
    }
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let key = container.allKeys.first
    switch key {
    case .market:
      let mode = try container.decode(
        RightMode.self,
        forKey: .market
      )
      self = .market(rightMode: mode)
    case .asset:
      let mode = try container.decode(
        RightMode.self,
        forKey: .asset
      )
      self = .asset(rightMode: mode)
    case .supply:
      self = .supply
    case .showLiquidityPool:
      self = .showLiquidityPool
    case .favourite:
      let mode = try container.decode(
        RightMode.self,
        forKey: .favourite
      )
      self = .favourite(rightMode: mode)
    case .nft:
      self = .nft
    default:
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Unabled to decode enum."
        )
      )
    }
  }
}

enum RightMode: Codable {
  enum Key: CodingKey {
    case rawValue
  }
  
  enum CodingError: Error {
    case unknownValue
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let rawValue = try container.decode(Int.self, forKey: .rawValue)
    switch rawValue {
    case 0:
      self = .lastPrice
    case 1:
      self = .value
    case 2:
      self = .ch24
    default:
      throw CodingError.unknownValue
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .lastPrice:
      try container.encode(0, forKey: .rawValue)
    case .value:
      try container.encode(1, forKey: .rawValue)
    case .ch24:
      try container.encode(2, forKey: .rawValue)
    }
  }
  
  case lastPrice
  case value
  case ch24
}

enum MarketSortType {
  case name(des: Bool)
  case ch24(des: Bool)
  case vol(des: Bool)
  case price(des: Bool)
  case cap(des: Bool)
}

class OverviewMainViewModel {
  var currentMode: ViewMode = Storage.retrieve(Constants.viewModeStoreFileName, as: ViewMode.self) ?? .asset(rightMode: .value) {
    didSet {
      Storage.store(self.currentMode, as: Constants.viewModeStoreFileName)
    }
  }
  var overviewMode: OverviewMode = .overview
  var dataSource: ThreadProtectedObject<[String: [OverviewMainCellViewModel]]> = .init(storageValue: [:])
  var displayDataSource: ThreadProtectedObject<[String: [OverviewMainCellViewModel]]> = .init(storageValue: [:])
  var displayNFTDataSource: ThreadProtectedObject<[String: [OverviewNFTCellViewModel]]> = .init(storageValue: [:])
  var displayNFTHeader: ThreadProtectedObject<[NFTSection]> = .init(storageValue: [])
  var summaryDataSource: ThreadProtectedObject<[OverviewSummaryCellViewModel]> = .init(storageValue: [])
  var displayLPDataSource: ThreadProtectedObject<[String: [OverviewLiquidityPoolViewModel]]> = .init(storageValue: [:])
  var displayHeader: ThreadProtectedObject<[SectionKeyType]> = .init(storageValue: [])
  
  var displayTotalValues: ThreadProtectedObject<[String: String]> = .init(storageValue: [:])
  var hideBalanceStatus: Bool = UserDefaults.standard.bool(forKey: Constants.hideBalanceKey) {
    didSet {
      UserDefaults.standard.set(self.hideBalanceStatus, forKey: Constants.hideBalanceKey)
    }
  }
  var marketSortType: MarketSortType = .ch24(des: true)
  var currencyMode: CurrencyMode
  var hiddenNFTSections = Set<Int>()
  var isHidingSmallAssetsToken = true
  var isRefreshingTableView = false
  var didTapAddNFTHeader: (() -> Void)?
  var didTapSectionButtonHeader: (( _ : UIButton) -> Void)?
  let queue = DispatchQueue(label: "overview.property.lock.queue")
  var currentChain: ChainType {
    didSet {
      if self.currentChain == .all {
        UserDefaults.standard.set(true, forKey: Constants.didSelectAllChainOption)
      } else {
        UserDefaults.standard.set(false, forKey: Constants.didSelectAllChainOption)
      }
    }
  }
  var currentWalletName: String {
    return AppDelegate.session.address.name
  }
  var assetChainBalanceModels: [ChainBalanceModel] = []
  var chainLiquidityPoolModels: [ChainLiquidityPoolModel] = []
  var badgeNumber: Int = 0
  
  init() {
    if let savedCurrencyMode = CurrencyMode(rawValue: UserDefaults.standard.integer(forKey: Constants.currentCurrencyMode)) {
      self.currencyMode = savedCurrencyMode.isQuoteCurrency ? KNGeneralProvider.shared.quoteCurrency : savedCurrencyMode
    } else {
      self.currencyMode = .usd
    }
    
    if UserDefaults.standard.bool(forKey: Constants.didSelectAllChainOption) {
      self.currentChain = .all
    } else {
      if let saved = Storage.retrieve(Constants.currentChainSaveFileName, as: ChainType.self) {
        self.currentChain = saved
      } else {
        self.currentChain = .all
      }
    }
  }
  
  func clearCache() {
    self.assetChainBalanceModels = []
    self.chainLiquidityPoolModels = []
  }
  
  func isEmpty() -> Bool {
    switch self.currentMode {
    case .asset:
        return self.dataSource.value[""]?.isEmpty ?? true
    case .market, .favourite:
      return self.displayDataSource.value[""]?.isEmpty ?? true
    case .supply, .showLiquidityPool:
      return self.displayHeader.value.isEmpty
    case .nft:
      return self.displayNFTHeader.value.isEmpty
    }
  }
  
  func filterSmallAssetTokens(balanceModels: [BalanceModel]) -> [BalanceModel] {
    let filterValues = balanceModels.filter { balance in
      var doubleValue: Double = 0
      if let currentQuoteValue = balance.quotes[self.currencyMode.toString()] {
        doubleValue = currentQuoteValue.value
      }
      let valueString = StringFormatter.currencyString(value: doubleValue, symbol: self.currencyMode.toString())
      return valueString.doubleValue > 0
    }
    return filterValues
  }
  
  func shouldShowHideButton() -> Bool {
    if self.currentChain == .all {
      return true
    } else {
      if let assetChainBalanceModels = self.assetChainBalanceModels.first {
        let filteredTokens = filterSmallAssetTokens(balanceModels: assetChainBalanceModels.balances)
        return assetChainBalanceModels.balances.count != filteredTokens.count
      }
      return false
    }
  }
  
  func updateCurrencyMode(mode: CurrencyMode) {
    self.currencyMode = mode
    self.reloadSummaryChainData()
  }

  func reloadSummaryChainData() {
    let summaryChainModels = BalanceStorage.shared.getSummaryChainModels()
    var total = 0.0
    self.summaryDataSource.value.forEach { data in
      total += data.value
    }

    let totalBigInt = BigInt(total * pow(10.0, 18.0))// - hideAndDeleteTotal

    let array: [OverviewSummaryCellViewModel] = summaryChainModels.map({ summaryModel in
      //re-calculate value and percent for each chain by subtract to hide or delete tokens
      if let unitValueModel = summaryModel.quotes[self.currencyMode.toString()] {
        let hideAndDeleteBigInt = KNSupportedTokenStorage.shared.getHideAndDeleteTokensBalanceUSD(self.currencyMode, chainType: summaryModel.chainType())
        let chainBalanceBigInt = BigInt(unitValueModel.value * pow(10.0, 18.0)) - hideAndDeleteBigInt
        if totalBigInt > 0 {
          summaryModel.percentage = chainBalanceBigInt.doubleUSDValue(currencyDecimal: self.currencyMode.decimalNumber()) / totalBigInt.doubleUSDValue(currencyDecimal: self.currencyMode.decimalNumber())
        }
      }
      
      let viewModel = OverviewSummaryCellViewModel(dataModel: summaryModel, currency: self.currencyMode)
      viewModel.hideBalanceStatus = self.hideBalanceStatus
      return viewModel
    })
    self.summaryDataSource.value = array
  }
  
  func reloadAssetData(mode: RightMode) {
    var displayModels: [OverviewMainCellViewModel] = []
    var dataSourceModels: [OverviewMainCellViewModel] = []
    var total:Double = 0
    self.assetChainBalanceModels.forEach { chainBalanceModel in
      // filter lending token
      let chainType = ChainType.make(chainID: chainBalanceModel.chainId) ?? KNGeneralProvider.shared.currentChain
      let lendingBalances = BalanceStorage.shared.getAllLendingBalances(chainType)
      var lendingSymbols: [String] = []
      lendingBalances.forEach { (lendingPlatform) in
        lendingPlatform.balances.forEach { (balance) in
          lendingSymbols.append(balance.interestBearingTokenSymbol.lowercased())
        }
      }
      var filterValues = chainBalanceModel.balances.filter { balance in
        return !lendingSymbols.contains(balance.token.symbol.lowercased())
      }
      var displayModel = filterValues.map { balance -> OverviewMainCellViewModel in
        let viewModel = OverviewMainCellViewModel(mode: .asset(token: balance.token, rightMode: mode), currency: self.currencyMode)
        viewModel.chainName = chainBalanceModel.chainName
        viewModel.chainId = chainBalanceModel.chainId
        viewModel.chainLogo = chainBalanceModel.chainLogo
        viewModel.tag = balance.token.tag
        viewModel.balance = balance.balance
        viewModel.quotes = balance.quotes
        viewModel.decimals = balance.token.decimals
        viewModel.hideBalanceStatus = self.hideBalanceStatus
        if let currentQuoteValue = balance.quotes[self.currencyMode.toString()] {
          total += currentQuoteValue.value
        }
        return viewModel
      }
      dataSourceModels.append(contentsOf: displayModel)
      if self.isHidingSmallAssetsToken {
          displayModel = displayModel.filter { cellVM in
              var doubleValue: Double = 0
              if let currentQuoteValue = cellVM.quotes[self.currencyMode.toString()] {
                doubleValue = currentQuoteValue.value
              }
              let valueString = StringFormatter.currencyString(value: doubleValue, symbol: self.currencyMode.toString())
              return valueString.doubleValue > 0
          }
      }
      displayModels.append(contentsOf: displayModel)
    }
    
    displayModels = displayModels.sorted(by: { firstModel, secondModel in
      var quote1Value: Double = 0.0
      var quote2Value: Double = 0.0
      if let quote1 = firstModel.quotes["usd"] {
        quote1Value = quote1.value
      }
      if let quote2 = secondModel.quotes["usd"] {
        quote2Value = quote2.value
      }

      if quote1Value == quote2Value, quote1Value == 0 {
        let balance1 = firstModel.balance.amountBigInt(decimals: firstModel.decimals) ?? BigInt(0)
        let balance2 = secondModel.balance.amountBigInt(decimals: secondModel.decimals) ?? BigInt(0)
        return balance1 > balance2
      } else {
        let stringValue1 = StringFormatter.currencyString(value: quote1Value, symbol: "usd")
        let stringValue2 = StringFormatter.currencyString(value: quote2Value, symbol: "usd")
        return stringValue1.doubleValue > stringValue2.doubleValue
      }
    })
    self.displayHeader.value = []
    self.displayDataSource.value = ["": displayModels]
    self.dataSource.value = ["": dataSourceModels]
    let displayTotalString = self.currencyMode.symbol() + StringFormatter.currencyString(value: total, symbol: self.currencyMode.toString()) + self.currencyMode.suffixSymbol()
    self.displayTotalValues.value["all"] = displayTotalString
    self.displayNFTHeader.value = []
    self.displayNFTDataSource.value = [:]
  }
  
  func reloadLPData() {
    var total = 0.0
    let currencyFormatter = StringFormatter()
    var models: [String: [OverviewLiquidityPoolViewModel]] = [:]
    var headers: [SectionKeyType] = []
    var headerTotalValue: [String: Double] = [:]
    self.chainLiquidityPoolModels.forEach { chainLPModel in
      let liquidityPoolData = self.getLiquidityPools(currency: self.currencyMode, allLiquidityPool: chainLPModel.balances)
      //TODO: temp fix replace later
      let header: [SectionKeyType] = liquidityPoolData.0.map({ e in
        return SectionKeyType(key: e, chain: nil)
      })
      header.forEach { item in
        if !headers.contains( where: {$0.key == item.key}) {
          headers.append(item)
        }
      }
      let data = liquidityPoolData.1
      header.forEach { (key) in
        var totalSection = 0.0
        var sectionModels: [OverviewLiquidityPoolViewModel] = []
        //value for total balance of current pool
        data[key.key.lowercased()]?.forEach({ (item) in
          if let poolPairToken = item as? [LPTokenModel] {
            poolPairToken.forEach { token in
              //add total value of each token in current pair
              totalSection += token.getTokenValue(self.currencyMode)
            }
            let cellVM = OverviewLiquidityPoolViewModel(currency: self.currencyMode, pairToken: poolPairToken)
            cellVM.chainId = chainLPModel.chainId
            cellVM.chainName = chainLPModel.chainName
            cellVM.chainLogo = chainLPModel.chainLogo
            sectionModels.append(cellVM)
          }
        })
        let currentSectionModels = models[key.key] ?? []
        models[key.key] = currentSectionModels + sectionModels
        
        let currentHeaderTotalValue = headerTotalValue[key.key] ?? 0.0
        headerTotalValue[key.key] = currentHeaderTotalValue + totalSection
        
        total += totalSection
      }
    }
    
    headers.forEach { (key) in
      let currentHeaderTotalValue = headerTotalValue[key.key] ?? 0.0
      let valueString = currencyFormatter.currencyString(value: currentHeaderTotalValue, decimals: self.currencyMode.decimalNumber())
      let displayTotalSection = !self.currencyMode.symbol().isEmpty ? self.currencyMode.symbol() + valueString : valueString + self.currencyMode.suffixSymbol()

      self.displayTotalValues.value[key.key] = displayTotalSection
    }
    
    self.displayHeader.value = headers
    self.displayLPDataSource.value = models
    let valueString = currencyFormatter.currencyString(value: total, decimals: self.currencyMode.decimalNumber())
    self.displayTotalValues.value["all"] = !self.currencyMode.symbol().isEmpty ? self.currencyMode.symbol() + valueString : valueString + self.currencyMode.suffixSymbol()
    self.displayNFTHeader.value = []
    self.displayNFTDataSource.value = [:]
  }
  
  func getLiquidityPools(currency: CurrencyMode, allLiquidityPool: [LiquidityPoolModel]) -> ([String], [String: [Any]]) {
    var poolDict: [String: [Any]] = [:]
    var allProject: [String] = []

    allLiquidityPool.forEach { poolModel in
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
      allLiquidityPool.forEach { poolModel in
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
  
  func reloadAllData() {
    reloadSummaryChainData()
    switch self.currentMode {
    case .market(let mode):
      let marketToken = KNSupportedTokenStorage.shared.marketTokens.sorted { (left, right) -> Bool in
        switch self.marketSortType {
        case .name(des: let des):
          return des ? left.symbol > right.symbol : left.symbol < right.symbol
        case .ch24(des: let des):
          return des ? left.getTokenChange24(self.currencyMode) > right.getTokenChange24(self.currencyMode) : left.getTokenChange24(self.currencyMode) < right.getTokenChange24(self.currencyMode)
        case .vol(des: let des):
          return des ? left.getVol(self.currencyMode) > right.getVol(self.currencyMode) : left.getVol(self.currencyMode) < right.getVol(self.currencyMode)
        case .price(des: let des):
          return des ? left.getTokenLastPrice(self.currencyMode) > right.getTokenLastPrice(self.currencyMode) : left.getTokenLastPrice(self.currencyMode) < right.getTokenLastPrice(self.currencyMode)
        case .cap(des: let des):
          return des ? left.getMarketCap(self.currencyMode) > right.getMarketCap(self.currencyMode) : left.getMarketCap(self.currencyMode) < right.getMarketCap(self.currencyMode)
        }
      }
      self.displayHeader.value = []
      let models = marketToken.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item, rightMode: mode), currency: self.currencyMode)
      }
      self.dataSource.value = ["": models]
      self.displayDataSource.value = ["": models]
      self.displayTotalValues.value = [:]
      self.displayNFTHeader.value = []
      self.displayNFTDataSource.value = [:]
    case .asset(let mode):
      self.reloadAssetData(mode: mode)
    case .supply:
      let supplyBalance = BalanceStorage.shared.getSupplyBalances(self.currentChain)
      self.displayHeader.value = supplyBalance.0
      let data = supplyBalance.1
      var models: [String: [OverviewMainCellViewModel]] = [:]
      var total = BigInt(0)
      var emptyHeaders: [SectionKeyType] = []
      self.displayHeader.value.forEach { (key) in
        var sectionModels: [OverviewMainCellViewModel] = []
        var totalSection = BigInt(0)
        data[key.toString()]?.forEach({ (item) in
          if let lendingBalance = item as? LendingBalance {
            if !lendingBalance.hasSmallAmount {
              totalSection += lendingBalance.getValueBigInt(self.currencyMode)
              sectionModels.append(OverviewMainCellViewModel(mode: .supply(balance: item), currency: self.currencyMode))
            }
          } else if let distributionBalance = item as? LendingDistributionBalance {
            totalSection += distributionBalance.getValueBigInt(self.currencyMode)
            sectionModels.append(OverviewMainCellViewModel(mode: .supply(balance: item), currency: self.currencyMode))
          }
        })
        if sectionModels.isEmpty {
          emptyHeaders.append(key)
        } else {
          models[key.toString()] = sectionModels.sorted(by: { leftE, rightE in
            return leftE.supplyValueBigInt > rightE.supplyValueBigInt
          })
          let displayTotalSection = self.currencyMode.symbol() + totalSection.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
          self.displayTotalValues.value[key.toString()] = displayTotalSection
          total += totalSection
        }
      }
      
      if emptyHeaders.isNotEmpty {
        emptyHeaders.forEach { e in
          self.displayHeader.value.removeAll { i in
            return i.key == e.key && i.chain == e.chain
          }
        }
      }
      
      self.dataSource.value = models
      self.displayDataSource.value = models
      self.displayTotalValues.value["all"] = self.currencyMode.symbol() + total.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
      self.displayNFTHeader.value = []
      self.displayNFTDataSource.value = [:]
    case .showLiquidityPool:
      self.reloadLPData()
    case .favourite(let mode):
      let marketToken = KNSupportedTokenStorage.shared.allActiveTokens.sorted { (left, right) -> Bool in
        switch self.marketSortType {
        case .name(des: let des):
          return des ? left.symbol > right.symbol : left.symbol < right.symbol
        case .ch24(des: let des):
          return des ? left.getTokenPrice().usd24hChange > right.getTokenPrice().usd24hChange : left.getTokenPrice().usd24hChange < right.getTokenPrice().usd24hChange
        case .vol(des: let des):
          return des ? left.getVol(self.currencyMode) > right.getVol(self.currencyMode) : left.getVol(self.currencyMode) < right.getVol(self.currencyMode)
        case .price(des: let des):
          return des ? left.getTokenLastPrice(self.currencyMode) > right.getTokenLastPrice(self.currencyMode) : left.getTokenLastPrice(self.currencyMode) < right.getTokenLastPrice(self.currencyMode)
        case .cap(des: let des):
          return des ? left.getMarketCap(self.currencyMode) > right.getMarketCap(self.currencyMode) : left.getMarketCap(self.currencyMode) < right.getMarketCap(self.currencyMode)
        }
      }.filter { (token) -> Bool in
        return KNSupportedTokenStorage.shared.getFavedStatusWithAddress(token.address)
      }
      self.displayHeader.value = []
      let models = marketToken.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item, rightMode: mode), currency: self.currencyMode)
      }
      self.dataSource.value = ["": models]
      self.displayDataSource.value = ["": models]
      self.displayTotalValues.value.removeAll()
      self.displayNFTHeader.value = []
      self.displayNFTDataSource.value = [:]
    case .nft:
      self.dataSource.value = [:]
      self.displayDataSource.value = [:]
      self.displayHeader.value = []
      self.displayNFTDataSource.value = [:]
      self.displayNFTHeader.value = []
      let nftSections = BalanceStorage.shared.getNFTBalanceForChain(self.currentChain)
      self.displayNFTHeader.value = nftSections
      nftSections.forEach({ item in
        var viewModels: [OverviewNFTCellViewModel] = []
        if !item.items.isEmpty {
          if item.items.count <= 2 {
            viewModels.append(OverviewNFTCellViewModel(item1: item.items[safeIndex: 0], item2: item.items[safeIndex: 1], category1: item, category2: item))
          } else {
            let chucked = item.items.chunked(into: 2)
            let vm = chucked.map { slided in
              return OverviewNFTCellViewModel(item1: slided[safeIndex: 0], item2: slided[safeIndex: 1], category1: item, category2: item)
            }
            viewModels.append(contentsOf: vm)
          }
        }
        self.displayNFTDataSource.value[item.collectibleName] = viewModels
      })
      
      let favedItems = BalanceStorage.shared.getAllFavedItems(self.currentChain)
      if !favedItems.isEmpty {
        let favSection = NFTSection(collectibleName: "Favorite NFT", collectibleAddress: "", collectibleSymbol: "FAV", collectibleLogo: "", items: [])
        self.displayNFTHeader.value.insert(favSection, at: 0)
        var viewModels: [OverviewNFTCellViewModel] = []
        if favedItems.count <= 2 {
          viewModels.append(OverviewNFTCellViewModel(item1: favedItems[safeIndex: 0]?.0, item2: favedItems[safeIndex: 1]?.0, category1: favedItems[safeIndex: 0]?.1, category2: favedItems[safeIndex: 1]?.1, isFav: true))
        } else {
          let chucked = favedItems.chunked(into: 2)
          let vm = chucked.map { slided in
            return OverviewNFTCellViewModel(item1: slided[safeIndex: 0]?.0, item2: slided[safeIndex: 1]?.0, category1: slided[safeIndex: 0]?.1, category2: slided[safeIndex: 1]?.1, isFav: true)
          }
          viewModels.append(contentsOf: vm)
        }
        self.displayNFTDataSource.value[favSection.collectibleName] = viewModels
      }
      if !self.displayNFTHeader.value.isEmpty {
        guard self.currentChain != .all else { return }
        let addMoreSection = NFTSection(collectibleName: "add-more-krystal", collectibleAddress: "", collectibleSymbol: "ADDMORE", collectibleLogo: "", items: [])
        let existed = self.displayNFTHeader.value.first { e in
          return e.collectibleSymbol == "ADDMORE"
        }
        if existed == nil {
          self.displayNFTHeader.value.append(addMoreSection)
        }
      }
    }
  }
  
  var numberOfSections: Int {
    if self.overviewMode == .summary {
      return 1
    }
    
    guard !self.isEmpty() else {
      return 1
    }
    if self.currentMode == .nft {
      return self.displayNFTHeader.value.count
    } else {
      return self.displayHeader.value.isEmpty ? 1 : self.displayHeader.value.count
    }
  }
  
  func getViewModelsForSection(_ section: Int) -> [OverviewMainCellViewModel] {
    guard !self.displayHeader.value.isEmpty else {
      return self.displayDataSource.value[""] ?? []
    }
    
    let key = self.displayHeader.value[section]
    return self.displayDataSource.value[key.toString()] ?? []
  }
  
  func numberOfRowsInSection(section: Int) -> Int {
    if self.overviewMode == .summary {
      return self.summaryDataSource.value.count
    }
    guard !self.isEmpty() else {
      return 1
    }
    switch self.currentMode {
    case .nft:
      guard !self.hiddenNFTSections.contains(section) else {
        return 0
      }
      let key = self.displayNFTHeader.value[section].collectibleName
      return self.displayNFTDataSource.value[key]?.count ?? 0
    case .asset:
      // + 1 row for hide/show small asset cell
      return self.getViewModelsForSection(section).count + 1
    case .showLiquidityPool:
      let key = self.displayHeader.value[section]
      return self.displayLPDataSource.value[key.key]?.count ?? 0
    default:
      return self.getViewModelsForSection(section).count
    }
  }
  
  func heightForRowAt(_ indexPath: IndexPath) -> CGFloat {
    if self.overviewMode == .summary {
      return 80
    }
    guard !self.isEmpty() else {
      return 400
    }
    switch self.currentMode {
    case .asset, .market, .favourite:
      return OverviewMainViewCell.kCellHeight
    case .supply:
      return OverviewDepositTableViewCell.kCellHeight
    case.showLiquidityPool:
      return OverviewLiquidityPoolCell.kCellHeight
    case .nft:
      return OverviewNFTTableViewCell.kCellHeight
    }
  }
  
  func heightForHeaderInSection() -> CGFloat {
    guard self.overviewMode == .overview else {
      return 0
    }
    guard self.currentMode == .supply || self.currentMode == .nft || self.currentMode == .showLiquidityPool else {
      return 0
    }
    return 40
  }
  
  @objc func addNFTButtonTapped(sender: UIButton) {
    if let didTapAddNFTHeader = didTapAddNFTHeader {
      didTapAddNFTHeader()
    }
  }
  
  @objc func sectionButtonTapped(sender: UIButton) {
    if let didTapSectionButtonHeader = didTapSectionButtonHeader {
      didTapSectionButtonHeader(sender)
    }
  }
  
  func viewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView? {
    guard self.overviewMode == .overview else {
      return nil
    }
    guard self.currentMode == .supply || self.currentMode == .nft || self.currentMode == .showLiquidityPool else {
      return nil
    }
    guard !self.displayHeader.value.isEmpty || !self.displayNFTHeader.value.isEmpty else {
      return nil
    }
    guard !self.isEmpty() else {
      return nil
    }
    if self.currentMode == .nft {
      let sectionItem = self.displayNFTHeader.value[section]
      let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
      view.backgroundColor = .clear
      guard sectionItem.collectibleSymbol != "ADDMORE" else {
        let button = UIButton(frame: view.frame.inset(by: UIEdgeInsets(top: 0, left: 37, bottom: 3, right: 37)))
        button.setTitle("Add NFT", for: .normal)
        button.rounded(color: UIColor(named: "normalTextColor")!, width: 1, radius: 16)
        button.setTitleColor(UIColor(named: "normalTextColor")!, for: .normal)
        button.titleLabel?.font = UIFont.Kyber.regular(with: 16)
        button.addTarget(self, action: #selector(addNFTButtonTapped(sender:)), for: .touchUpInside)
        view.addSubview(button)
        return view
      }
      
      let icon = UIImageView(frame: CGRect(x: 29, y: 0, width: 32, height: 32))
      icon.center.y = view.center.y
      if sectionItem.collectibleSymbol == "FAV" {
        icon.image = UIImage(named: "fav_section_icon")
      } else {
        icon.setImage(with: sectionItem.collectibleLogo, placeholder: UIImage(named: "placeholder_nft_section"), size: CGSize(width: 32, height: 32), applyNoir: false)
        if let chain = sectionItem.chainType {
          let iconChain = UIImageView(frame: CGRect(x: 20, y: 20, width: 12, height: 12))
          iconChain.image = chain.chainIcon()
          icon.addSubview(iconChain)
        }
        
      }
      
      view.addSubview(icon)
      
      let titleLabel = UILabel(frame: CGRect(x: 72, y: 0, width: 200, height: 40))
      titleLabel.center.y = view.center.y
      titleLabel.text = sectionItem.collectibleName
      titleLabel.font = UIFont.Kyber.regular(with: 18)
      titleLabel.textColor = UIColor(named: "textWhiteColor")
      view.addSubview(titleLabel)
      
      let arrowIcon = UIImageView(frame: CGRect(x: tableView.frame.size.width - 27 - 24, y: 0, width: 24, height: 24))
      arrowIcon.image = UIImage(named: "arrow_down_template")
      arrowIcon.tintColor = UIColor(named: "textWhiteColor")
      view.addSubview(arrowIcon)
      let button = UIButton(frame: view.frame)
      button.tag = section
      button.addTarget(self, action: #selector(sectionButtonTapped), for: .touchUpInside)
      view.addSubview(button)
      return view
    } else {
      let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
      view.backgroundColor = .clear
      let rightTextString = self.getTotalValueForSection(section)
      let rightLabelWidth = rightTextString.width(withConstrainedHeight: 40, font: UIFont.Kyber.regular(with: 18))
      
      let titleText = self.displayHeader.value[section]
      let titleTextWidth = titleText.key.width(withConstrainedHeight: 40, font: UIFont.Kyber.regular(with: 18))
      let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: titleTextWidth, height: 40))
      titleLabel.center.y = view.center.y
      titleLabel.text = titleText.key
      titleLabel.font = UIFont.Kyber.regular(with: 18)
      titleLabel.textColor = UIColor(named: "textWhiteColor")
      view.addSubview(titleLabel)
      
      let valueLabel = UILabel(frame: CGRect(x: tableView.frame.size.width - rightLabelWidth - 35, y: 0, width: rightLabelWidth, height: 40))
      valueLabel.text = rightTextString
      valueLabel.font = UIFont.Kyber.regular(with: 18)
      valueLabel.textAlignment = .right
      valueLabel.textColor = UIColor(named: "textWhiteColor")
      view.addSubview(valueLabel)
      
      if let chain = titleText.chain {
        let iconChain = UIImageView(frame: CGRect(x: 8, y: 0, width: 12, height: 12))
        iconChain.image = chain.chainIcon()
        
        let chainTitle = chain.chainName()
        
        let chainTitleWidth = chainTitle.width(withConstrainedHeight: 20, font: UIFont.Kyber.regular(with: 12))
        
        let containerChainView = UIView(frame: CGRect(x: titleLabel.frame.origin.x + titleLabel.frame.size.width + 8, y: 0, width: 32 + chainTitleWidth, height: 20))
        containerChainView.backgroundColor = UIColor(named: "toolbarBgColor")
        containerChainView.center.y = view.center.y
        
        iconChain.center.y = 10
        containerChainView.addSubview(iconChain)
        
        let chainNameLabel = UILabel(frame: CGRect(x: 24, y: 0, width: chainTitleWidth, height: 20))
        chainNameLabel.text = chainTitle
        chainNameLabel.font = UIFont.Kyber.regular(with: 12)
        chainNameLabel.textColor = UIColor(named: "normalTextColor")
        chainNameLabel.center.y = 10
        containerChainView.addSubview(chainNameLabel)
        
        containerChainView.rounded(cornerRadius: 8)
        
        view.addSubview(containerChainView)
      }

      return view
    }
  }
  
  var displayPageTotalValue: String {
    guard self.currentMode != .market(rightMode: .ch24), self.currentMode != .favourite(rightMode: .ch24), self.currentMode != .nft else {
      return ""
    }
    guard !self.hideBalanceStatus else {
      return "********"
    }
    return self.displayTotalValues.value["all"] ?? ""
  }
  
  func getTotalValueForSection(_ section: Int) -> String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let key = self.displayHeader.value[section]
    return self.displayTotalValues.value[key.toString()] ?? ""
  }
  
  var displayTotalValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    
    guard let isDefaultValue = self.summaryDataSource.value.first?.isDefaultValue, isDefaultValue == false else {
      return self.defaultDisplayTotalValue
    }
    let currentChainViewModel = self.summaryDataSource.value.first { viewModel in
      viewModel.chainType == KNGeneralProvider.shared.currentChain
    }
    guard let total = currentChainViewModel?.value else {
      return self.defaultDisplayTotalValue
    }
    let displayValue = BigInt(total * pow(10.0, 18.0))
    return self.currencyMode.symbol() + NumberFormatUtils.valueFormat(value: displayValue, decimals: 18, currencyMode: self.currencyMode) + self.currencyMode.suffixSymbol()
  }
  
  var defaultDisplayTotalValue: String {
    let total = BalanceStorage.shared.getTotalBalance(self.currencyMode)
    return self.currencyMode.symbol() + total.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
  }
  
  var displayTotalSummaryValue: String {
    guard let isDefaultValue = self.summaryDataSource.value.first?.isDefaultValue, isDefaultValue == false else {
      return "--"
    }
    guard !self.hideBalanceStatus else {
      return "********"
    }
    var total = 0.0
    self.summaryDataSource.value.forEach { data in
      total += data.value
    }
    let displayValue = BigInt(total * pow(10.0, 18.0))
    return self.currencyMode.symbol() + NumberFormatUtils.valueFormat(value: displayValue, decimals: 18, currencyMode: self.currencyMode) + self.currencyMode.suffixSymbol()
    
  }
  
  var displayHideBalanceImage: UIImage {
    return self.hideBalanceStatus ? UIImage(named: "hide_eye_icon")! : UIImage(named: "show_eye_icon")!
  }
  
  var displayCurrentPageName: String {
    switch self.currentMode {
    case .asset:
      return "Assets"
    case .market:
      return "Market"
    case .supply:
      return "Supply"
    case .showLiquidityPool:
      return "Liquidity Pool Tokens"
    case .favourite:
      return "Favourite"
    case .nft:
      return "NFT"
    }
  }
  
  func getChainForSection(_ section: Int) -> ChainType? {
    return self.displayHeader.value[section].chain
  }
}
