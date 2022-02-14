//
//  OverviewMainViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 13/10/2021.
//
import BigInt
import UIKit

enum OverviewMainViewEvent {
  case send
  case receive
  case search
  case notifications
  case changeMode(current: ViewMode)
  case walletConfig
  case select(token: Token)
  case selectListWallet
  case withdrawBalance(platform: String, balance: LendingBalance)
  case claim(balance: LendingDistributionBalance)
  case depositMore
  case changeRightMode(current: ViewMode)
  case addNFT
  case openNFTDetail(item: NFTItem, category: NFTSection)
  case didAppear
  case pullToRefreshed(current: ViewMode, overviewMode: OverviewMode)
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

enum CurrencyMode: Int {
  case usd = 0
  case eth
  case btc
  case bnb
  case matic
  case avax
  case cro
  case ftm
  
  func symbol() -> String {
    switch self {
    case .usd:
      return "$"
    case .btc:
      return "₿"
    case .eth:
      return "⧫"
    case .bnb:
      return ""
    case .matic:
      return ""
    case .avax:
      return ""
    case .cro:
      return ""
    case .ftm:
      return ""
    }
  }
  
  func suffixSymbol() -> String {
    switch self {
    case .usd:
      return ""
    case .btc:
      return ""
    case .eth:
      return ""
    case .bnb:
      return " BNB"
    case .matic:
      return " MATIC"
    case .avax:
      return " AVAX"
    case .cro:
      return " CRO"
    case .ftm:
      return " FTM"
    }
  }
  
  func toString() -> String {
    switch self {
    case .eth:
      return "eth"
    case .usd:
      return "usd"
    case .btc:
      return "btc"
    case .bnb:
      return "bnb"
    case .matic:
      return "matic"
    case .avax:
      return "avax"
    case .cro:
      return "cro"
    case .ftm:
      return "ftm"
    }
  }

  func decimalNumber() -> Int {
    switch self {
    case .eth:
      return DecimalNumber.eth
    case .usd:
      return DecimalNumber.usd
    case .btc:
      return DecimalNumber.btc
    case .bnb:
      return DecimalNumber.bnb
    case .matic:
      return DecimalNumber.matic
    case .avax:
      return DecimalNumber.avax
    case .cro:
      return DecimalNumber.cro
    case .ftm:
      return DecimalNumber.ftm
    }
  }
  
  var isQuoteCurrency: Bool {
    return self == .eth || self == .bnb || self == .matic || self == .avax || self == .cro || self == .ftm
  }
}

class OverviewMainViewModel {
  var session: KNSession!
  var currentMode: ViewMode = Storage.retrieve(Constants.viewModeStoreFileName, as: ViewMode.self) ?? .asset(rightMode: .value) {
    didSet {
      Storage.store(self.currentMode, as: Constants.viewModeStoreFileName)
    }
  }
  var overviewMode: OverviewMode = .overview
  var dataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayDataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayNFTDataSource: [String: [OverviewNFTCellViewModel]] = [:]
  var displayNFTHeader: [NFTSection] = []
  var summaryDataSource: [OverviewSummaryCellViewModel] = []
  var displayLPDataSource: [String: [OverviewLiquidityPoolViewModel]] = [:]
  var displayHeader: [String] = []
  var displayTotalValues: [String: String] = [:]
  var hideBalanceStatus: Bool = UserDefaults.standard.bool(forKey: Constants.hideBalanceKey) {
    didSet {
      UserDefaults.standard.set(self.hideBalanceStatus, forKey: Constants.hideBalanceKey)
    }
  }
  var marketSortType: MarketSortType = .ch24(des: true)
  var currencyMode: CurrencyMode
  var hiddenSections = Set<Int>()
  var isHidingSmallAssetsToken = true
  var isRefreshingTableView = false
  var didTapAddNFTHeader: (() -> Void)?
  var didTapSectionButtonHeader: (( _ : UIButton) -> Void)?
  init(session: KNSession) {
    if let savedCurrencyMode = CurrencyMode(rawValue: UserDefaults.standard.integer(forKey: Constants.currentCurrencyMode)) {
      self.currencyMode = savedCurrencyMode.isQuoteCurrency ? KNGeneralProvider.shared.quoteCurrency : savedCurrencyMode
    } else {
      self.currencyMode = .usd
    }
    self.session = session
  }

  func isEmpty() -> Bool {
    switch self.currentMode {
    case .asset, .market, .favourite:
      return self.displayDataSource[""]?.isEmpty ?? true
    case .supply, .showLiquidityPool:
      return self.displayHeader.isEmpty
    case .nft:
      return self.displayNFTHeader.isEmpty
    }
  }

  func filterSmallAssetTokens(tokens: [Token]) -> [Token] {
    let filteredTokens = tokens.filter({ token in
      let rateBigInt = BigInt(token.getTokenLastPrice(self.currencyMode) * pow(10.0, 18.0))
      let valueBigInt = token.getBalanceBigInt() * rateBigInt / BigInt(10).power(token.decimals)
      if let doubleValue = Double(valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber())) {
        return doubleValue > 0
      }
      return true
    })
    return filteredTokens
  }

  func shouldShowHideButton() -> Bool {
    let assetTokens = KNSupportedTokenStorage.shared.getAssetTokens()
    let filteredTokens = filterSmallAssetTokens(tokens: assetTokens)
    return assetTokens.count != filteredTokens.count
  }

  func updateCurrencyMode(mode: CurrencyMode) {
    self.currencyMode = mode
    self.reloadSummaryChainData()
  }

  func reloadSummaryChainData() {
    let summaryChainModels = BalanceStorage.shared.getSummaryChainModels()
    var total = 0.0
    self.summaryDataSource.forEach { data in
      total += data.value
    }
    let hideAndDeleteTotal = KNSupportedTokenStorage.shared.getAllChainHideAndDeleteTokensBalanceUSD(self.currencyMode)
    let totalBigInt = BigInt(total * pow(10.0, 18.0)) - hideAndDeleteTotal
    
    //convert đang bị nil ở đây
    let totalDoubleValue = totalBigInt.doubleUSDValue(currencyDecimal: self.currencyMode.decimalNumber())//Double(totalBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()))

    self.summaryDataSource = summaryChainModels.map({ summaryModel in
      //re-calculate value and percent for each chain by subtract to hide or delete tokens
      if let unitValueModel = summaryModel.quotes[self.currencyMode.toString()] {
        let hideAndDeleteBigInt = KNSupportedTokenStorage.shared.getHideAndDeleteTokensBalanceUSD(self.currencyMode, chainType: summaryModel.chainType())
        let hideAndDeleteValue = hideAndDeleteBigInt.doubleUSDValue(currencyDecimal: self.currencyMode.decimalNumber())
        let chainBalanceValue = unitValueModel.value - hideAndDeleteValue
        if totalDoubleValue > 0 {
          summaryModel.percentage = chainBalanceValue / totalDoubleValue
        }
      }
      let viewModel = OverviewSummaryCellViewModel(dataModel: summaryModel, currency: self.currencyMode)
      viewModel.hideBalanceStatus = self.hideBalanceStatus
      return viewModel
    })
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
      self.displayHeader = []
      let models = marketToken.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item, rightMode: mode), currency: self.currencyMode)
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
      self.displayTotalValues = [:]
      self.displayNFTHeader = []
      self.displayNFTDataSource = [:]
    case .asset(let mode):
      var assetTokens = KNSupportedTokenStorage.shared.getAssetTokens().sorted { (left, right) -> Bool in
        return left.getValueBigInt(self.currencyMode) > right.getValueBigInt(self.currencyMode)
      }

      if self.isHidingSmallAssetsToken {
        assetTokens = self.filterSmallAssetTokens(tokens: assetTokens)
      }

      self.displayHeader = []
      self.displayTotalValues = [:]
      var total = BigInt(0)
      let models = assetTokens.map { (item) -> OverviewMainCellViewModel in
        total += item.getValueBigInt(self.currencyMode)
        let viewModel = OverviewMainCellViewModel(mode: .asset(token: item, rightMode: mode), currency: self.currencyMode)
        viewModel.tag = item.tag
        return viewModel
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
      let displayTotalString = self.currencyMode.symbol() + total.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
      self.displayTotalValues["all"] = displayTotalString
      self.displayNFTHeader = []
      self.displayNFTDataSource = [:]
    case .supply:
      let supplyBalance = BalanceStorage.shared.getSupplyBalances()
      self.displayHeader = supplyBalance.0
      let data = supplyBalance.1
      var models: [String: [OverviewMainCellViewModel]] = [:]
      var total = BigInt(0)
      self.displayHeader.forEach { (key) in
        var sectionModels: [OverviewMainCellViewModel] = []
        var totalSection = BigInt(0)
        data[key]?.forEach({ (item) in
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
        models[key] = sectionModels
        let displayTotalSection = self.currencyMode.symbol() + totalSection.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
        self.displayTotalValues[key] = displayTotalSection
        total += totalSection
      }
      self.dataSource = models
      self.displayDataSource = models
      self.displayTotalValues["all"] = self.currencyMode.symbol() + total.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
      self.displayNFTHeader = []
      self.displayNFTDataSource = [:]
    case .showLiquidityPool:
        let liquidityPoolData = BalanceStorage.shared.getLiquidityPools(currency: self.currencyMode)
        self.displayHeader = liquidityPoolData.0
        let data = liquidityPoolData.1
        var models: [String: [OverviewLiquidityPoolViewModel]] = [:]
        var total = 0.0
        let currencyFormatter = StringFormatter()
        self.displayHeader.forEach { (key) in
          var sectionModels: [OverviewLiquidityPoolViewModel] = []
          //value for total balance of current pool
          var totalSection = 0.0
          data[key.lowercased()]?.forEach({ (item) in
            if let poolPairToken = item as? [LPTokenModel] {
              poolPairToken.forEach { token in
                //add total value of each token in current pair
                totalSection += token.getTokenValue(self.currencyMode)
              }
              sectionModels.append(OverviewLiquidityPoolViewModel(currency: self.currencyMode, pairToken: poolPairToken))
            }
          })

          models[key] = sectionModels
          let valueString = currencyFormatter.currencyString(value: totalSection, decimals: self.currencyMode.decimalNumber())
          let displayTotalSection = !self.currencyMode.symbol().isEmpty ? self.currencyMode.symbol() + valueString : valueString + self.currencyMode.suffixSymbol()

          self.displayTotalValues[key] = displayTotalSection
          total += totalSection
        }
        self.displayLPDataSource = models
        let valueString = currencyFormatter.currencyString(value: total, decimals: self.currencyMode.decimalNumber())
        self.displayTotalValues["all"] = !self.currencyMode.symbol().isEmpty ? self.currencyMode.symbol() + valueString : valueString + self.currencyMode.suffixSymbol()
        self.displayNFTHeader = []
        self.displayNFTDataSource = [:]
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
      self.displayHeader = []
      let models = marketToken.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item, rightMode: mode), currency: self.currencyMode)
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
      self.displayTotalValues = [:]
      self.displayNFTHeader = []
      self.displayNFTDataSource = [:]
    case .nft:
      self.dataSource = [:]
      self.displayDataSource = [:]
      self.displayHeader = []
      self.displayNFTDataSource = [:]
      let nftSections = BalanceStorage.shared.getAllNFTBalance()
      self.displayNFTHeader = nftSections
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
        self.displayNFTDataSource[item.collectibleName] = viewModels
      })
      
      let favedItems = BalanceStorage.shared.getAllFavedItems()
      if !favedItems.isEmpty {
        let favSection = NFTSection(collectibleName: "Favorite NFT", collectibleAddress: "", collectibleSymbol: "FAV", collectibleLogo: "", items: [])
        self.displayNFTHeader.insert(favSection, at: 0)
        var viewModels: [OverviewNFTCellViewModel] = []
        if favedItems.count <= 2 {
          viewModels.append(OverviewNFTCellViewModel(item1: favedItems[safeIndex: 0]?.0, item2: favedItems[safeIndex: 1]?.0, category1: favedItems[safeIndex: 0]?.1, category2: favedItems[safeIndex: 1]?.1))
        } else {
          let chucked = favedItems.chunked(into: 2)
          let vm = chucked.map { slided in
            return OverviewNFTCellViewModel(item1: slided[safeIndex: 0]?.0, item2: slided[safeIndex: 1]?.0, category1: slided[safeIndex: 0]?.1, category2: slided[safeIndex: 1]?.1)
          }
          viewModels.append(contentsOf: vm)
        }
        self.displayNFTDataSource[favSection.collectibleName] = viewModels
      }
      if !self.displayNFTHeader.isEmpty {
        let addMoreSection = NFTSection(collectibleName: "add-more-krystal", collectibleAddress: "", collectibleSymbol: "ADDMORE", collectibleLogo: "", items: [])
        self.displayNFTHeader.append(addMoreSection)
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
      return self.displayNFTHeader.count
    } else {
      return self.displayHeader.isEmpty ? 1 : self.displayHeader.count
    }
  }

  func getViewModelsForSection(_ section: Int) -> [OverviewMainCellViewModel] {
    guard !self.displayHeader.isEmpty else {
      return self.displayDataSource[""] ?? []
    }

    let key = self.displayHeader[section]
    return self.displayDataSource[key] ?? []
  }

  func numberOfRowsInSection(section: Int) -> Int {
    if self.overviewMode == .summary {
      return self.summaryDataSource.count
    }
    guard !self.isEmpty() else {
      return 1
    }
    guard !self.hiddenSections.contains(section) else {
        return 0
    }

    switch self.currentMode {
    case .nft:
      let key = self.displayNFTHeader[section].collectibleName
      return self.displayNFTDataSource[key]?.count ?? 0
    case .asset:
      // + 1 row for hide/show small asset cell
      return self.getViewModelsForSection(section).count + 1
    case .showLiquidityPool:
      let key = self.displayHeader[section]
      return self.displayLPDataSource[key]?.count ?? 0
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
    case.supply:
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
    guard !self.displayHeader.isEmpty || !self.displayNFTHeader.isEmpty else {
      return nil
    }
    guard !self.isEmpty() else {
      return nil
    }
    if self.currentMode == .nft {
      let sectionItem = self.displayNFTHeader[section]
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
      let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: tableView.frame.size.width - rightLabelWidth - 70, height: 40))
      titleLabel.center.y = view.center.y
      titleLabel.text = self.displayHeader[section]
      titleLabel.font = UIFont.Kyber.regular(with: 18)
      titleLabel.textColor = UIColor(named: "textWhiteColor")
      view.addSubview(titleLabel)

      let valueLabel = UILabel(frame: CGRect(x: tableView.frame.size.width - rightLabelWidth - 35, y: 0, width: rightLabelWidth, height: 40))
      valueLabel.text = rightTextString
      valueLabel.font = UIFont.Kyber.regular(with: 18)
      valueLabel.textAlignment = .right
      valueLabel.textColor = UIColor(named: "textWhiteColor")
      view.addSubview(valueLabel)

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
    return self.displayTotalValues["all"] ?? ""
  }

  func getTotalValueForSection(_ section: Int) -> String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let key = self.displayHeader[section]
    return self.displayTotalValues[key] ?? ""
  }

  var displayTotalValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }

    guard let isDefaultValue = self.summaryDataSource.first?.isDefaultValue, isDefaultValue == false else {
      return self.defaultDisplayTotalValue
    }
    let currentChainViewModel = self.summaryDataSource.first { viewModel in
      viewModel.chainType == KNGeneralProvider.shared.currentChain
    }
    guard let total = currentChainViewModel?.value else {
      return self.defaultDisplayTotalValue
    }

    let hideAndDeleteTotal = KNSupportedTokenStorage.shared.getHideAndDeleteTokensBalanceUSD(self.currencyMode, chainType: KNGeneralProvider.shared.currentChain)
    let displayValue = BigInt(total * pow(10.0, 18.0)) - hideAndDeleteTotal
    return self.currencyMode.symbol() + displayValue.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
  }

  var defaultDisplayTotalValue: String {
    let total = BalanceStorage.shared.getTotalBalance(self.currencyMode)
    return self.currencyMode.symbol() + total.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
  }

  var displayTotalSummaryValue: String {
    guard let isDefaultValue = self.summaryDataSource.first?.isDefaultValue, isDefaultValue == false else {
      return "--"
    }
    guard !self.hideBalanceStatus else {
      return "********"
    }
    var total = 0.0
    self.summaryDataSource.forEach { data in
      total += data.value
    }

    let hideAndDeleteTotal = KNSupportedTokenStorage.shared.getAllChainHideAndDeleteTokensBalanceUSD(self.currencyMode)
    let displayValue = BigInt(total * pow(10.0, 18.0)) - hideAndDeleteTotal
    return self.currencyMode.symbol() + displayValue.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
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
        return "Liquidity Pool"
    case .favourite:
      return "Favourite"
    case .nft:
      return "NFT"
    }
  }
}
