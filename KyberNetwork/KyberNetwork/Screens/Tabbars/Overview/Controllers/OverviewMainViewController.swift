//
//  OverviewMainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/9/21.
//

import UIKit
import BigInt

enum OverviewMainViewEvent {
  case send
  case receive
  case search
  case notifications
  case changeMode(current: ViewMode)
  case walletConfig(currency: CurrencyMode)
  case select(token: Token)
  case selectListWallet
  case withdrawBalance(platform: String, balance: LendingBalance)
  case claim(balance: LendingDistributionBalance)
  case depositMore
  case changeRightMode(current: ViewMode)
  case addNFT
  case openNFTDetail(item: NFTItem, category: NFTSection)
}

enum ViewMode: Equatable, Codable {
  case market(rightMode: RightMode)
  case asset(rightMode: RightMode)
  case supply
  case favourite(rightMode: RightMode)
  case nft
  
  public static func == (lhs: ViewMode, rhs: ViewMode) -> Bool {
    switch (lhs, rhs) {
    case ( .market, .market):
      return true
    case ( .asset, .asset):
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
    case market, asset, supply, favourite, nft
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
    }
  }
  
  func decimalNumber() -> Int {
    switch self {
    case .eth:
      return 4
    case .usd:
      return 2
    case .btc:
      return 5
    case .bnb:
      return 4
    case .matic:
      return 4
    case .avax:
      return 4
    }
  }
  
  var isQuoteCurrency: Bool {
    return self == .eth || self == .bnb || self == .matic
  }
}

protocol OverviewMainViewControllerDelegate: class {
  func overviewMainViewController(_ controller: OverviewMainViewController, run event: OverviewMainViewEvent)
}

class OverviewMainViewModel {
  fileprivate var session: KNSession!
  var currentMode: ViewMode = Storage.retrieve(Constants.viewModeStoreFileName, as: ViewMode.self) ?? .asset(rightMode: .value) {
    didSet {
      Storage.store(self.currentMode, as: Constants.viewModeStoreFileName)
    }
  }
  var dataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayDataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayNFTDataSource: [String: [OverviewNFTCellViewModel]] = [:]
  var displayNFTHeader: [NFTSection] = []
  var displayHeader: [String] = []
  var displayTotalValues: [String: String] = [:]
  var hideBalanceStatus: Bool = UserDefaults.standard.bool(forKey: Constants.hideBalanceKey) {
    didSet {
      UserDefaults.standard.set(self.hideBalanceStatus, forKey: Constants.hideBalanceKey)
    }
  }
  var marketSortType: MarketSortType = .ch24(des: true)
  var currencyMode: CurrencyMode = .usd
  var hiddenSections = Set<Int>()
  
  init(session: KNSession) {
    self.session = session
  }

  func isEmpty() -> Bool {
    switch self.currentMode {
    case .asset, .market, .favourite:
      return self.displayDataSource[""]?.isEmpty ?? true
    case .supply:
      return self.displayHeader.isEmpty
    case .nft:
      return self.displayNFTHeader.isEmpty
    }
  }

  func reloadAllData() {
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
      let assetTokens = KNSupportedTokenStorage.shared.getAssetTokens().sorted { (left, right) -> Bool in
        return left.getValueBigInt(self.currencyMode) > right.getValueBigInt(self.currencyMode)
      }
      self.displayHeader = []
      self.displayTotalValues = [:]
      var total = BigInt(0)
      let models = assetTokens.map { (item) -> OverviewMainCellViewModel in
        total += item.getValueBigInt(self.currencyMode)
        return OverviewMainCellViewModel(mode: .asset(token: item, rightMode: mode), currency: self.currencyMode)
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
            totalSection += lendingBalance.getValueBigInt(self.currencyMode)
          } else if let distributionBalance = item as? LendingDistributionBalance {
            totalSection += distributionBalance.getValueBigInt(self.currencyMode)
          }
          sectionModels.append(OverviewMainCellViewModel(mode: .supply(balance: item), currency: self.currencyMode))
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
    case .favourite(let mode):
      let marketToken = KNSupportedTokenStorage.shared.allTokens.sorted { (left, right) -> Bool in
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
    return self.displayHeader.isEmpty ? 1 : self.displayHeader.count
  }

  func getViewModelsForSection(_ section: Int) -> [OverviewMainCellViewModel] {
    guard !self.displayHeader.isEmpty else {
      return self.displayDataSource[""] ?? []
    }
    
    let key = self.displayHeader[section]
    return self.displayDataSource[key] ?? []
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
    let total = BalanceStorage.shared.getTotalBalance(self.currencyMode)
    return self.currencyMode.symbol() + total.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
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
    case .favourite:
      return "Favourite"
    case .nft:
      return "NFT"
    }
  }
}

class OverviewMainViewController: KNBaseViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var totalBalanceContainerView: UIView!
  @IBOutlet weak var currentWalletLabel: UILabel!
  @IBOutlet weak var totalBalanceLabel: UILabel!
  @IBOutlet weak var hideBalanceButton: UIButton!
  @IBOutlet weak var notificationButton: UIButton!
  @IBOutlet weak var searchButton: UIButton!
  @IBOutlet weak var totalPageValueLabel: UILabel!
  @IBOutlet weak var currentPageNameLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!
  @IBOutlet weak var currentChainIcon: UIImageView!
  @IBOutlet weak var currentChainLabel: UILabel!
  @IBOutlet weak var sortingContainerView: UIView!
  @IBOutlet weak var sortMarketByNameButton: UIButton!
  @IBOutlet weak var sortMarketByCh24Button: UIButton!
  
  @IBOutlet weak var sortMarketByPrice: UIButton!
  @IBOutlet weak var sortMarketByVol: UIButton!
  
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var rightModeSortLabel: UILabel!
  @IBOutlet var sortButtons: [UIButton]!
  
  weak var delegate: OverviewMainViewControllerDelegate?
  
  let viewModel: OverviewMainViewModel
  
  init(viewModel: OverviewMainViewModel) {
    self.viewModel = viewModel
    super.init(nibName: OverviewMainViewController.className, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: OverviewMainViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewMainViewCell.kCellID
    )
    
    let nibSupply = UINib(nibName: OverviewDepositTableViewCell.className, bundle: nil)
    self.tableView.register(
      nibSupply,
      forCellReuseIdentifier: OverviewDepositTableViewCell.kCellID
    )
    
    let nibEmpty = UINib(nibName: OverviewEmptyTableViewCell.className, bundle: nil)
    self.tableView.register(
      nibEmpty,
      forCellReuseIdentifier: OverviewEmptyTableViewCell.kCellID
    )
    
    let nibNFT = UINib(nibName: OverviewNFTTableViewCell.className, bundle: nil)
    self.tableView.register(
      nibNFT,
      forCellReuseIdentifier: OverviewNFTTableViewCell.kCellID
    )
    
    self.tableView.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUISwitchChain()
  }

  fileprivate func updateUIHideBalanceButton() {
    self.hideBalanceButton.setImage(self.viewModel.displayHideBalanceImage, for: .normal)
  }
  
  fileprivate func updateUIWalletList() {
    self.walletNameLabel.text = self.viewModel.session.wallet.getWalletObject()?.name ?? "---"
  }

  fileprivate func reloadUI() {
    self.viewModel.reloadAllData()
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.currentPageNameLabel.text = self.viewModel.displayCurrentPageName
    self.updateUIHideBalanceButton()
    self.sortingContainerView.isHidden = self.viewModel.currentMode != .market(rightMode: .ch24)
    self.updateUIWalletList()
    self.updateCh24Button()
    self.tableView.reloadData()
  }

  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.chainIconImage
    self.currentChainIcon.image = icon
    self.currentChainLabel.text = KNGeneralProvider.shared.quoteToken.uppercased()
  }
  
  fileprivate func updateCh24Button() {
    if case .market(let rightMode) = self.viewModel.currentMode {
      switch rightMode {
      case .ch24:
        self.sortMarketByCh24Button.tag = 2
        self.rightModeSortLabel.text = "24h"
      default:
        self.sortMarketByCh24Button.tag = 5
        self.rightModeSortLabel.text = "Cap"
      }
    }
    self.updateUISortBar()
  }

  fileprivate func updateUISortBar() {
    var selectedTypeTag = 0
    var selectedDes = false
    switch self.viewModel.marketSortType {
    case .name(des: let des):
      selectedTypeTag = 1
      selectedDes = des
    case .vol(des: let des):
      selectedTypeTag = 3
      selectedDes = des
    case .price(des: let des):
      selectedTypeTag = 4
      selectedDes = des
    case .ch24(des: let des):
      selectedTypeTag = 2
      selectedDes = des
    case .cap(des: let des):
      selectedTypeTag = 5
      selectedDes = des
    }
    self.sortButtons.forEach { button in
      if button.tag == selectedTypeTag {
        self.updateUIForIndicatorView(button: button, dec: selectedDes)
      } else {
        button.setImage(UIImage(named: "sort_none_icon"), for: .normal)
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.reloadUI()
  }

  @IBAction func sendButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .send)
  }
  
  @IBAction func receiveButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .receive)
  }
  
  @IBAction func walletsListButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .selectListWallet)
  }
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = { selected in
      let viewModel = SwitchChainWalletsListViewModel(selected: selected)
      let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
      self.present(secondPopup, animated: true, completion: nil)
    }
    self.present(popup, animated: true, completion: nil)
  }

  @IBAction func hideBalanceButtonTapped(_ sender: UIButton) {
    self.viewModel.hideBalanceStatus = !self.viewModel.hideBalanceStatus
    self.reloadUI()
  }

  @IBAction func toolbarOptionButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .changeMode(current: self.viewModel.currentMode))
  }

  @IBAction func walletOptionButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .walletConfig(currency: self.viewModel.currencyMode))
  }
  
  @IBAction func sortingButtonTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      if case let .name(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .name(des: !dec)
      } else {
        self.viewModel.marketSortType = .name(des: true)
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "market_sort_name", customAttributes: nil)
    } else if sender.tag == 2 {
      if case let .ch24(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .ch24(des: !dec)
      } else {
        self.viewModel.marketSortType = .ch24(des: true)
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "market_sort_24h", customAttributes: nil)
    } else if sender.tag == 3 {
      if case let .vol(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .vol(des: !dec)
      } else {
        self.viewModel.marketSortType = .vol(des: true)
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "market_sort_vol", customAttributes: nil)
    } else  if sender.tag == 4 {
      if case let .price(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .price(des: !dec)
      } else {
        self.viewModel.marketSortType = .price(des: true)
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "market_sort_price", customAttributes: nil)
    } else  if sender.tag == 5 {
      if case let .cap(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .cap(des: !dec)
      } else {
        self.viewModel.marketSortType = .cap(des: true)
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "market_sort_cap", customAttributes: nil)
    }
    self.viewModel.reloadAllData()
    self.reloadUI()
  }

  @IBAction func notificationsButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .notifications)
  }

  @IBAction func searchButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .search)
  }
  
  @objc func sectionButtonTapped(sender: UIButton) {
    print("Button Clicked \(sender.tag)")
    let section = sender.tag
    
    func indexPathsForSection() -> [IndexPath] {
      var indexPaths = [IndexPath]()
      let key = self.viewModel.displayNFTHeader[section].collectibleName
      if let range = self.viewModel.displayNFTDataSource[key]?.count {
        for row in 0..<range {
          indexPaths.append(IndexPath(row: row,
                                      section: section))
        }
      }

      return indexPaths
    }
    
    if self.viewModel.hiddenSections.contains(section) {
        self.viewModel.hiddenSections.remove(section)
        self.tableView.insertRows(at: indexPathsForSection(),
                                  with: .fade)
    } else {
        self.viewModel.hiddenSections.insert(section)
        self.tableView.deleteRows(at: indexPathsForSection(),
                                  with: .fade)
    }
  }
  
  @objc func addNFTButtonTapped(sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .addNFT)
  }

  fileprivate func updateUIForIndicatorView(button: UIButton, dec: Bool) {
    if dec {
      let img = UIImage(named: "sort_down_icon")
      button.setImage(img, for: .normal)
    } else {
      let img = UIImage(named: "sort_up_icon")
      button.setImage(img, for: .normal)
    }
  }

  func coordinatorDidSelectMode(_ mode: ViewMode) {
    self.viewModel.currentMode = mode
    self.reloadUI()
  }
  
  func coordinatorDidUpdateChain() {
    guard self.isViewLoaded else {
      return
    }
    if self.viewModel.currencyMode.isQuoteCurrency {
      self.viewModel.currencyMode = KNGeneralProvider.shared.quoteCurrency
    }
    self.updateUISwitchChain()
    self.reloadUI()
  }
  
  func coordinatorDidUpdateNewSession(_ session: KNSession) {
    self.viewModel.session = session
    guard self.isViewLoaded else { return }
    self.updateUIWalletList()
    self.viewModel.reloadAllData()
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.tableView.reloadData()
  }
  
  func coordinatorDidUpdateDidUpdateTokenList() {
    guard self.isViewLoaded else { return }
    self.viewModel.reloadAllData()
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.tableView.reloadData()
  }
  
  func coordinatorDidUpdateCurrencyMode(_ mode: CurrencyMode) {
    self.viewModel.currencyMode = mode
    self.reloadUI()
  }
}

extension OverviewMainViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    guard !self.viewModel.isEmpty() else {
      return 1
    }
    if self.viewModel.currentMode == .nft {
      return self.viewModel.displayNFTHeader.count
    } else {
      return self.viewModel.numberOfSections
    }
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard !self.viewModel.isEmpty() else {
      return 1
    }
    if self.viewModel.currentMode == .nft {
      if self.viewModel.hiddenSections.contains(section) {
          return 0
      }
      let key = self.viewModel.displayNFTHeader[section].collectibleName
      return self.viewModel.displayNFTDataSource[key]?.count ?? 0
    } else {
      return self.viewModel.getViewModelsForSection(section).count
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard !self.viewModel.isEmpty() else {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewEmptyTableViewCell.kCellID,
        for: indexPath
      ) as! OverviewEmptyTableViewCell
      switch self.viewModel.currentMode {
      case .asset:
        cell.imageIcon.image = UIImage(named: "empty_asset_icon")
        cell.titleLabel.text = "Your balance is empty"
        cell.button1.isHidden = KNGeneralProvider.shared.currentChain != .eth
        cell.button1.setTitle("Buy ETH", for: .normal)
        cell.action = {
            self.navigationController?.openSafari(with: "https://krystal.app/buy-crypto.html")
        }
        cell.button2.isHidden = true
      case .favourite:
        cell.imageIcon.image = UIImage(named: "empty_fav_token")
        cell.titleLabel.text = "No Favourite Token yet"
        cell.button1.isHidden = true
        cell.button2.isHidden = true
      case .supply:
        cell.imageIcon.image = UIImage(named: "deposit_empty_icon")
        cell.titleLabel.text = "You've not supplied any token to earn interest"
        cell.button1.isHidden = false
        cell.button2.isHidden = false
        cell.action = {
          self.delegate?.overviewMainViewController(self, run: .depositMore)
        }
      case .market:
        cell.imageIcon.image = UIImage(named: "empty_token_token")
        cell.titleLabel.text = "Your token list is empty"
        cell.button1.isHidden = true
        cell.button2.isHidden = true
      case .nft:
        cell.imageIcon.image = UIImage(named: "empty_nft")
        cell.titleLabel.text = "You have not any NFT"
        cell.button1.isHidden = false
        cell.button2.isHidden = true
        cell.button1.setTitle("Add NFT", for: .normal)
        cell.action = {
          self.delegate?.overviewMainViewController(self, run: .addNFT)
        }
      }
      return cell
    }
    switch self.viewModel.currentMode {
    case .asset, .market, .favourite:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewMainViewCell.kCellID,
        for: indexPath
      ) as! OverviewMainViewCell

      let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
      cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
      cell.updateCell(cellModel)
      cell.action = {
        self.delegate?.overviewMainViewController(self, run: .changeRightMode(current: self.viewModel.currentMode))
      }
      return cell
    case .supply:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewDepositTableViewCell.kCellID,
        for: indexPath
      ) as! OverviewDepositTableViewCell
      let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
      cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
      cell.updateCell(cellModel)
      return cell
    case .nft:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewNFTTableViewCell.kCellID,
        for: indexPath
      ) as! OverviewNFTTableViewCell
      let key = self.viewModel.displayNFTHeader[indexPath.section].collectibleName
      if let viewModel = self.viewModel.displayNFTDataSource[key]?[indexPath.row] {
        cell.updateCell(viewModel)
      }
      cell.completeHandle = { item, category in
        self.delegate?.overviewMainViewController(self, run: .openNFTDetail(item: item, category: category))
      }
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
    guard self.viewModel.currentMode == .supply || self.viewModel.currentMode == .nft else {
      return nil
    }
    guard !self.viewModel.displayHeader.isEmpty || !self.viewModel.displayNFTHeader.isEmpty else {
      return nil
    }
    guard !self.viewModel.isEmpty() else {
      return nil
    }
    if self.viewModel.currentMode == .nft {
      
      let sectionItem = self.viewModel.displayNFTHeader[section]
      
      
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
      let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: 100, height: 40))
      titleLabel.center.y = view.center.y
      titleLabel.text = self.viewModel.displayHeader[section]
      titleLabel.font = UIFont.Kyber.regular(with: 18)
      titleLabel.textColor = UIColor(named: "textWhiteColor")
      view.addSubview(titleLabel)
      
      let valueLabel = UILabel(frame: CGRect(x: tableView.frame.size.width - 100 - 35, y: 0, width: 100, height: 40))
      valueLabel.text = self.viewModel.getTotalValueForSection(section)
      valueLabel.font = UIFont.Kyber.regular(with: 18)
      valueLabel.textAlignment = .right
      valueLabel.textColor = UIColor(named: "textWhiteColor")
      view.addSubview(valueLabel)

      return view
    }
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    guard self.viewModel.currentMode == .supply || self.viewModel.currentMode == .nft else {
      return 0
    }
    return 40
  }
}

extension OverviewMainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard !self.viewModel.isEmpty() else {
      return
    }
    guard self.viewModel.currentMode != .nft else {
      return
    }
    let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
    switch cellModel.mode {
    case .asset(token: let token, _):
      self.delegate?.overviewMainViewController(self, run: .select(token: token))
    case .market(token: let token, _):
      self.delegate?.overviewMainViewController(self, run: .select(token: token))
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        let platform = self.viewModel.displayHeader[indexPath.section]
        self.delegate?.overviewMainViewController(self, run: .withdrawBalance(platform: platform, balance: lendingBalance))
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        self.delegate?.overviewMainViewController(self, run: .claim(balance: distributionBalance))
      }
    case .search:
      break
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard !self.viewModel.isEmpty() else {
      return 400
    }
    switch self.viewModel.currentMode {
    case .asset, .market, .favourite:
      return OverviewMainViewCell.kCellHeight
    case.supply:
      return OverviewDepositTableViewCell.kCellHeight
    case .nft:
      return OverviewNFTTableViewCell.kCellHeight
    }
  }
}

extension OverviewMainViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let alpha = scrollView.contentOffset.y <= 0 ? abs(scrollView.contentOffset.y) / 200.0 : 0.0
    self.totalBalanceContainerView.alpha = alpha
  }
}
