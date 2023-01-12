//
//  OverviewMainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/9/21.
//

import UIKit
import BigInt
import SwipeCellKit
import MBProgressHUD
import KrystalWallets
import SkeletonView
import BaseModule
import DesignSystem
import TransactionModule

protocol OverviewMainViewControllerDelegate: class {
  func overviewMainViewController(_ controller: OverviewMainViewController, run event: OverviewMainViewEvent)
}

class OverviewMainViewController: BaseWalletOrientedViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var totalBalanceContainerView: UIView!
  @IBOutlet weak var notificationButton: UIButton!
  @IBOutlet weak var searchButton: UIButton!
  @IBOutlet weak var totalPageValueLabel: UILabel!
  @IBOutlet weak var currentPageNameLabel: UILabel!
  @IBOutlet weak var sortingContainerView: UIView!
  @IBOutlet weak var totatlInfoView: UIView!
  @IBOutlet weak var sortMarketByNameButton: UIButton!
  @IBOutlet weak var sortMarketByCh24Button: UIButton!
  @IBOutlet weak var sortMarketByPrice: UIButton!
  @IBOutlet weak var sortMarketByVol: UIButton!
  @IBOutlet weak var rightModeSortLabel: UILabel!
  @IBOutlet var sortButtons: [UIButton]!
  @IBOutlet weak var infoCollectionView: UICollectionView!
  @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var insestView: UIView!
  @IBOutlet weak var scanButton: UIButton!
  @IBOutlet weak var badgeNumberLabel: UILabel!
  
  weak var delegate: OverviewMainViewControllerDelegate?
  let refreshControl = UIRefreshControl()
  let viewModel: OverviewMainViewModel
  let calculatingQueue = DispatchQueue.global()
  
  override var supportAllChainOption: Bool {
    return true
  }
  
  override var currentChain: ChainType {
    return viewModel.currentChain
  }
  
  init(viewModel: OverviewMainViewModel) {
    self.viewModel = viewModel
    super.init(nibName: OverviewMainViewController.className, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var insetViewHeight: CGFloat {
    switch viewModel.overviewMode {
    case .overview:
      switch viewModel.currentMode {
      case .market, .favourite:
        return 280
      default:
        return 264
      }
    case .summary:
      return 200
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tabBarItem.accessibilityIdentifier = "menuHome"
    
    self.tableView.registerCellNib(OverviewMainViewCell.self)
    self.tableView.registerCellNib(OverviewAllChainTokenCell.self)
    self.tableView.registerCellNib(OverviewDepositTableViewCell.self)
    self.tableView.registerCellNib(OverviewLiquidityPoolCell.self)
    self.tableView.registerCellNib(OverviewMultichainLiquidityPoolCell.self)
    self.tableView.registerCellNib(OverviewEmptyTableViewCell.self)
    self.tableView.registerCellNib(OverviewNFTTableViewCell.self)
    self.tableView.registerCellNib(OverviewSummaryCell.self)
    self.tableView.registerCellNib(OverviewSkeletonCell.self)
    
    self.infoCollectionView.registerCellNib(OverviewTotalInfoCell.self)
    
    self.configPullToRefresh()
    self.configHeaderTapped()
    self.showLoadingSkeleton()
    self.view.isUserInteractionDisabledWhenSkeletonIsActive = true
    
    Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.minutes2,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.getNotificationBadgeNumber()
      }
    )
    updateUIBadgeNotification()
  }
  
  func configHeaderTapped() {
    self.viewModel.didTapAddNFTHeader = {
      self.delegate?.overviewMainViewController(self, run: .addNFT)
    }
    
    self.viewModel.didTapSectionButtonHeader = { sender in
      let section = sender.tag
      func indexPathsForSection() -> [IndexPath] {
        var indexPaths = [IndexPath]()
        let key = self.viewModel.displayNFTHeader.value[section].collectibleName
        if let range = self.viewModel.displayNFTDataSource.value[key]?.count {
          for row in 0..<range {
            indexPaths.append(IndexPath(row: row,
                                        section: section))
          }
        }
        
        return indexPaths
      }
      
      if self.viewModel.hiddenNFTSections.contains(section) {
        self.viewModel.hiddenNFTSections.remove(section)
        self.tableView.insertRows(at: indexPathsForSection(),
                                  with: .fade)
      } else {
        self.viewModel.hiddenNFTSections.insert(section)
        self.tableView.deleteRows(at: indexPathsForSection(),
                                  with: .fade)
      }
    }
  }
  
  func configPullToRefresh() {
    if shouldPullToRefresh() {
      self.refreshControl.tintColor = .lightGray
      self.refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
      self.tableView.addSubview(refreshControl)
    } else {
      self.refreshControl.removeFromSuperview()
    }
  }
    
    override func reloadWallet() {
        super.reloadWallet()
        if self.viewModel.currentChain != .all {
          self.viewModel.currentChain = KNGeneralProvider.shared.currentChain
        }
        viewModel.badgeNumber = 0
        getNotificationBadgeNumber()
        guard self.isViewLoaded else { return }
        calculatingQueue.async {
          self.viewModel.reloadAllData()
          self.delegate?.overviewMainViewController(self, run: .pullToRefreshed(current: self.viewModel.currentMode, overviewMode: self.viewModel.overviewMode))
          DispatchQueue.main.async {
            self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
            self.tableView.reloadData()
            self.infoCollectionView.reloadData()
            self.showLoadingSkeleton()
            self.updateUIBadgeNotification()
          }
        }
    }
  
  @objc func refresh(_ sender: AnyObject) {
    if self.viewModel.isRefreshingTableView {
      return
    }
    self.refreshControl.beginRefreshing()
    self.viewModel.isRefreshingTableView = true
    self.delegate?.overviewMainViewController(self, run: .pullToRefreshed(current: self.viewModel.currentMode, overviewMode: self.viewModel.overviewMode))
  }
  
  func shouldPullToRefresh() -> Bool {
    guard self.viewModel.overviewMode == .overview else {
      return true
    }
    switch self.viewModel.currentMode {
    case .supply, .asset, .showLiquidityPool, .nft:
      return true
    default:
      return false
    }
  }
  
  func getNotificationBadgeNumber() {
    guard FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.notiV2) else {
      return
    }
    delegate?.overviewMainViewController(self, run: .getBadgeNotification)
  }
  
  func updateUIBadgeNotification() {
    guard isViewLoaded else { return }
    guard FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.notiV2) else {
      badgeNumberLabel.isHidden = true
      return
    }
    if viewModel.badgeNumber > 0 {
      badgeNumberLabel.text = "\(viewModel.badgeNumber)".paddingString()
      badgeNumberLabel.isHidden = false
    } else {
      badgeNumberLabel.text = ""
      badgeNumberLabel.isHidden = true
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIByFeatureFlags()
    self.delegate?.overviewMainViewController(self, run: .didAppear)
    self.getNotificationBadgeNumber()
    
  }
  
  func updateUIByFeatureFlags() {
    scanButton.isHidden = !FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.scanner)
  }
  
  fileprivate func reloadUI() {
    guard isViewLoaded else { return }
    self.viewModel.reloadAllData()
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.currentPageNameLabel.text = self.viewModel.displayCurrentPageName
    self.sortingContainerView.isHidden = (self.viewModel.currentMode != .market(rightMode: .ch24) && self.viewModel.currentMode != .favourite(rightMode: .ch24)) || self.viewModel.overviewMode == .summary
    self.totatlInfoView.isHidden = self.viewModel.overviewMode == .summary
    self.insestView.frame.size.height = self.insetViewHeight
    self.updateUIByFeatureFlags()
    self.updateCh24Button()
    self.tableView.reloadData()
    self.infoCollectionView.reloadData()
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
    if viewModel.overviewMode == .summary {
      MixPanelManager.track("homepage_total_open", properties: ["screenid": "homepage_total"])
    } else {
      MixPanelManager.track("homepage_open", properties: ["screenid": "homepage"])
    }
  }

  override func onChainSelected(chain: ChainType) {
    showLoadingSkeleton()
    if chain == .all {
      self.viewModel.currentChain = chain
      self.tableView.reloadData()
      self.delegate?.overviewMainViewController(self, run: .selectAllChain)
      return
    } else {
      self.viewModel.currentChain = chain
      super.onChainSelected(chain: chain)
      self.delegate?.overviewMainViewController(self, run: .pullToRefreshed(current: self.viewModel.currentMode, overviewMode: self.viewModel.overviewMode))
    }
  }
  
  @IBAction func toolbarOptionButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .changeMode(current: self.viewModel.currentMode))
    
  }
  
  @IBAction func sortingButtonTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      if case let .name(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .name(des: !dec)
      } else {
        self.viewModel.marketSortType = .name(des: true)
      }
      Tracker.track(event: .marketSortName)
    } else if sender.tag == 2 {
      if case let .ch24(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .ch24(des: !dec)
      } else {
        self.viewModel.marketSortType = .ch24(des: true)
      }
      Tracker.track(event: .marketSort24h)
    } else if sender.tag == 3 {
      if case let .vol(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .vol(des: !dec)
      } else {
        self.viewModel.marketSortType = .vol(des: true)
      }
      Tracker.track(event: .marketSortVol)
    } else  if sender.tag == 4 {
      if case let .price(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .price(des: !dec)
      } else {
        self.viewModel.marketSortType = .price(des: true)
      }
      Tracker.track(event: .marketSortPrice)
    } else  if sender.tag == 5 {
      if case let .cap(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .cap(des: !dec)
      } else {
        self.viewModel.marketSortType = .cap(des: true)
      }
      Tracker.track(event: .marketSortCap)
    }
    self.reloadUI()
  }
  
  @IBAction func notificationsButtonTapped(_ sender: UIButton) {
    if FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.notiV2) {
      let vc = NotificationV2ViewController.instantiateFromNib()
      navigationController?.pushViewController(vc, animated: true)
    } else {
      self.delegate?.overviewMainViewController(self, run: .notifications)
    }
    MixPanelManager.track("home_noti", properties: ["screenid": "homepage"])
  }
  
  @IBAction func searchButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .search)
    MixPanelManager.track("home_search", properties: ["screenid": "homepage"])
  }
  
  @IBAction func scanWasTapped(_ sender: Any) {
    var acceptedResultTypes: [ScanResultType] = [.promotionCode]
    var scanModes: [ScanMode] = [.qr, .text]
    if KNGeneralProvider.shared.currentChain.isEVM {
      acceptedResultTypes.append(contentsOf: [.walletConnect, .ethPublicKey, .ethPrivateKey])
      scanModes = [.qr, .text]
    } else if KNGeneralProvider.shared.currentChain == .solana {
      acceptedResultTypes.append(contentsOf: [.solPublicKey, .solPrivateKey])
      scanModes = [.qr]
    }
    ScannerModule.start(previousScreen: ScreenName.explore, viewController: self, acceptedResultTypes: acceptedResultTypes, scanModes: scanModes) { [weak self] text, type in
      guard let self = self else { return }
      switch type {
      case .walletConnect:
        self.delegate?.overviewMainViewController(self, run: .scannedWalletConnect(url: text))
      case .ethPublicKey:
        self.delegate?.overviewMainViewController(self, run: .send(recipientAddress: text))
      case .ethPrivateKey:
        let currentChain = KNGeneralProvider.shared.currentChain
        if currentChain.isEVM {
          self.delegate?.overviewMainViewController(self, run: .importWallet(privateKey: text, chain: currentChain))
        } else {
          self.delegate?.overviewMainViewController(self, run: .importWallet(privateKey: text, chain: .eth))
        }
      case .solPublicKey:
        self.delegate?.overviewMainViewController(self, run: .send(recipientAddress: text))
      case .solPrivateKey:
        self.delegate?.overviewMainViewController(self, run: .importWallet(privateKey: text, chain: .solana))
      case .promotionCode:
        guard let code = ScannerUtils.getPromotionCode(text: text) else { return }
        self.delegate?.overviewMainViewController(self, run: .openPromotion(code: code))
      }
    }
    MixPanelManager.track("home_qr", properties: ["screenid": "homepage"])
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
    self.refreshControl.endRefreshing()
    self.configPullToRefresh()
    MixPanelManager.track("home_token_data_pop_up", properties: ["screenid": "homepage", "show_option": mode.toString()])
  }
  
  @objc override func onAppSwitchChain() {
    super.onAppSwitchChain()
    guard self.isViewLoaded else {
      return
    }
    self.onChainSelected(chain: KNGeneralProvider.shared.currentChain)
    if self.viewModel.currencyMode.isQuoteCurrency {
      self.viewModel.currencyMode = KNGeneralProvider.shared.quoteCurrency
    }
    self.reloadUI()
  }
  
  override func onAppSelectAllChain() {
      super.onAppSelectAllChain()
    self.onChainSelected(chain: .all)
  }
  
  func coordinatorDidUpdateCurrencyMode(_ mode: CurrencyMode) {
    self.viewModel.updateCurrencyMode(mode: mode)
    self.reloadUI()
  }
  
  func coordinatorPullToRefreshDone() {
    self.viewModel.isRefreshingTableView = false
    DispatchQueue.main.async {
      self.refreshControl.endRefreshing()
      self.view.hideSkeleton()
      self.reloadUI()
    }
  }
  
  func coordinatorDidUpdateAllTokenData(models: [ChainBalanceModel]) {
    self.viewModel.assetChainBalanceModels = models
    self.view.hideSkeleton()
    self.reloadUI()
  }
  
  func coordinatorDidUpdateAllLPData(models: [ChainLiquidityPoolModel]) {
    self.viewModel.chainLiquidityPoolModels = models
    self.reloadUI()
  }
  
  func overviewModeDidChanged(isSummary: Bool) {
    self.viewModel.overviewMode = isSummary ? .summary : .overview
    self.sortingContainerView.isHidden = (self.viewModel.currentMode != .market(rightMode: .ch24) && self.viewModel.currentMode != .favourite(rightMode: .ch24)) || self.viewModel.overviewMode == .summary
    self.totatlInfoView.isHidden = self.viewModel.overviewMode == .summary
    self.tableViewTopConstraint.constant = 0
    self.insestView.frame.size.height = insetViewHeight
    self.tableView.reloadData()
    self.configPullToRefresh()
    
  }
  
  func coordinatorDidUpdateNotificationBadgeNumber(number: Int) {
    viewModel.badgeNumber = number
    updateUIBadgeNotification()
  }

  static var hasSafeArea: Bool {
    guard #available(iOS 11.0, *), let topPadding = UIApplication.shared.keyWindow?.safeAreaInsets.top, topPadding > 24 else {
      return false
    }
    return true
  }
}

extension OverviewMainViewController {
  func numberOfSections(in tableView: UITableView) -> Int {
    self.viewModel.numberOfSections
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRowsInSection(section: section)
  }
  
  func emptyCell(indexPath: IndexPath) -> OverviewEmptyTableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewEmptyTableViewCell.kCellID,
      for: indexPath
    ) as! OverviewEmptyTableViewCell
    switch self.viewModel.currentMode {
    case .asset:
      cell.imageIcon.image = Images.emptyAsset
      cell.titleLabel.text = Strings.balanceIsEmpty
      cell.button1.setTitle(Strings.buyCrypto, for: .normal)
      cell.action = {
        self.delegate?.overviewMainViewController(self, run: .buyCrypto)
      }
      cell.button1.isHidden = false
      cell.button2.isHidden = true
    case .favourite:
      cell.imageIcon.image = Images.emptyFavToken
      cell.titleLabel.text = Strings.noFavoriteToken
      cell.button1.isHidden = true
      cell.button2.isHidden = true
    case .supply:
      cell.imageIcon.image = Images.emptyDeposit
      cell.titleLabel.text = Strings.notSuppliedAnyToken
      cell.button1.setTitle(Strings.supplyTokensToEarnInterest, for: .normal)
      cell.button1.isHidden = false
      cell.button2.isHidden = false
      cell.action = {
        self.delegate?.overviewMainViewController(self, run: .depositMore)
      }
    case .showLiquidityPool:
      cell.imageIcon.image = Images.emptyLiquidityPool
      cell.titleLabel.text = Strings.notHaveLiquidityPool
      cell.button1.isHidden = true
      cell.button2.isHidden = true
    case .market:
      cell.imageIcon.image = Images.emptyTokens
      cell.titleLabel.text = Strings.tokenListIsEmpty
      cell.button1.isHidden = true
      cell.button2.isHidden = true
    case .nft:
      cell.imageIcon.image = Images.emptyNFT
      cell.titleLabel.text = Strings.notHaveAnyNFT
      cell.button1.isHidden = false
      cell.button2.isHidden = true
      cell.button1.setTitle(Strings.addNFT, for: .normal)
      cell.action = {
        self.delegate?.overviewMainViewController(self, run: .addNFT)
      }
    }
    return cell
  }
  
  func tokenInfoCell(indexPath: IndexPath) -> OverviewMainViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewMainViewCell.kCellID,
      for: indexPath
    ) as! OverviewMainViewCell
    
    if let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[safe: indexPath.row] {
      cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
      cell.updateCell(cellModel)
    }

    cell.action = {
      self.delegate?.overviewMainViewController(self, run: .changeRightMode(current: self.viewModel.currentMode))
    }
    return cell
  }
  
  func multiChainTokenInfoCell(indexPath: IndexPath) -> OverviewAllChainTokenCell {
    let cell = tableView.dequeueReusableCell(OverviewAllChainTokenCell.self, indexPath: indexPath)!
    
    if let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[safe: indexPath.row] {
      cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
      cell.updateCell(cellModel)
    }
    
    cell.action = {
      self.delegate?.overviewMainViewController(self, run: .changeRightMode(current: self.viewModel.currentMode))
    }
    return cell
  }
  
  func showOrHideSmallValueTokenCell() -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: "showOrHideSmallValueTokenCell")
    cell.backgroundColor = UIColor(named: "mainViewBgColor")
    cell.textLabel?.textColor = UIColor(named: "buttonBackgroundColor")
    if self.viewModel.shouldShowHideButton() {
      cell.textLabel?.text = self.viewModel.isHidingSmallAssetsToken ? "Show all assets".toBeLocalised() : "Hide small assets".toBeLocalised()
    } else {
      cell.textLabel?.text = ""
    }
    
    cell.textLabel?.textAlignment = .center
    cell.textLabel?.font = UIFont.Kyber.regular(with: 14)
    cell.selectionStyle = .none
    return cell
  }
  
  func summaryCell(indexPath: IndexPath) -> OverviewSummaryCell {
    let cell = tableView.dequeueReusableCell(OverviewSummaryCell.self, indexPath: indexPath)!
    let chainModel = self.viewModel.summaryDataSource.value[indexPath.row]
    chainModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
    cell.updateCell(chainModel)
    return cell
  }
  
  func overviewTableViewCell(indexPath: IndexPath) -> UITableViewCell {
    guard !self.viewModel.isEmpty() else {
      return emptyCell(indexPath: indexPath)
    }
    
    switch self.viewModel.currentMode {
    case .asset:
      let isLastCell = indexPath.row == self.viewModel.numberOfRowsInSection(section: indexPath.section) - 1
      if self.viewModel.currentChain == .all {
        return isLastCell ? showOrHideSmallValueTokenCell() : multiChainTokenInfoCell(indexPath: indexPath)
      }
      return isLastCell ? showOrHideSmallValueTokenCell() : tokenInfoCell(indexPath: indexPath)
    case .market, .favourite:
      return tokenInfoCell(indexPath: indexPath)
    case .supply:
      let cell = tableView.dequeueReusableCell(OverviewDepositTableViewCell.self, indexPath: indexPath)!
      if let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[safe: indexPath.row] {
        cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
        cell.updateCell(cellModel)
      }
      
      return cell
    case .showLiquidityPool:
      if self.viewModel.currentChain == .all {
        let cell = tableView.dequeueReusableCell(OverviewMultichainLiquidityPoolCell.self, indexPath: indexPath)!
        let key = self.viewModel.displayHeader.value[indexPath.section]
        if let viewModel = self.viewModel.displayLPDataSource.value[key.key]?[indexPath.row] {
          viewModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
          cell.updateCell(viewModel)
        }
        return cell
      }
      let cell = tableView.dequeueReusableCell(OverviewLiquidityPoolCell.self, indexPath: indexPath)!
      let key = self.viewModel.displayHeader.value[indexPath.section]
      if let viewModel = self.viewModel.displayLPDataSource.value[key.key]?[indexPath.row] {
        viewModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
        cell.updateCell(viewModel)
      }
      return cell
    case .nft:
      let cell = tableView.dequeueReusableCell(OverviewNFTTableViewCell.self, indexPath: indexPath)!
      if let key = self.viewModel.displayNFTHeader.value[safe: indexPath.section]?.collectibleName {
        if let viewModel = self.viewModel.displayNFTDataSource.value[key]?[indexPath.row] {
          cell.updateCell(viewModel)
        }
      }
      
      cell.completeHandle = { item, category in
        self.delegate?.overviewMainViewController(self, run: .openNFTDetail(item: item, category: category))
      }
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch self.viewModel.overviewMode {
    case .overview:
      return overviewTableViewCell(indexPath: indexPath)
    case .summary:
      return summaryCell(indexPath: indexPath)
    }
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return self.viewModel.viewForHeaderInSection(tableView, section: section)
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return self.viewModel.heightForHeaderInSection()
  }
}

extension OverviewMainViewController: UITableViewDelegate {
  
  func isShowOrHideAssetRow(indexPath: IndexPath) -> Bool {
    switch self.viewModel.currentMode {
    case .asset:
      return indexPath.row == self.viewModel.numberOfRowsInSection(section: indexPath.section) - 1
    default:
      return false
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard self.viewModel.overviewMode == .overview else {
      return
    }
    guard !self.viewModel.isEmpty() else {
      return
    }
    guard self.viewModel.currentMode != .nft, self.viewModel.currentMode != .showLiquidityPool else {
      return
    }
    // if current mode is assets then check if user tap on show or hide row
    guard !isShowOrHideAssetRow(indexPath: indexPath) else {
      // user tap on show or hide row
      self.viewModel.isHidingSmallAssetsToken = !self.viewModel.isHidingSmallAssetsToken
      self.reloadUI()
      return
    }
    guard let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[safe: indexPath.row] else { return }
    switch cellModel.mode {
    case .asset(token: let token, _):
      self.delegate?.overviewMainViewController(self, run: .select(token: token, chainId: cellModel.chainId))
    case .market(token: let token, _):
      self.delegate?.overviewMainViewController(self, run: .select(token: token))
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {

        let platform = self.viewModel.displayHeader.value[indexPath.section]
        self.delegate?.overviewMainViewController(self, run: .withdrawBalance(platform: platform.key, balance: lendingBalance))
      } else if let distributionBalance = balance as? LendingDistributionBalance {

        self.delegate?.overviewMainViewController(self, run: .claim(balance: distributionBalance))
      }
    case .search:
      break
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return self.viewModel.heightForRowAt(indexPath)
  }
}

extension OverviewMainViewController: UIScrollViewDelegate {

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    guard scrollView == self.infoCollectionView else {
      return
    }
    let actualPosition = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
    
    if actualPosition.x < 0 {
      DispatchQueue.main.async {
        self.infoCollectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: true)
        self.overviewModeDidChanged(isSummary: true)
        MixPanelManager.track("homepage_total_open", properties: ["screenid": "homepage_total"])
      }
    } else {
      DispatchQueue.main.async {
        self.infoCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
        self.overviewModeDidChanged(isSummary: false)
        MixPanelManager.track("homepage_open", properties: ["screenid": "homepage"])
      }
    }
  }
  
}

extension OverviewMainViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 2
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(OverviewTotalInfoCell.self, indexPath: indexPath)!
    var totalValueString = ""
    if indexPath.row == 0 && self.viewModel.currentChain != .all {
      totalValueString = self.viewModel.displayTotalValue
    } else {
      totalValueString = self.viewModel.displayTotalSummaryValue
    }
    
    let isAllChainOverallCell = indexPath.item != 0
    
    cell.updateCell(chain: isAllChainOverallCell ? .all : viewModel.currentChain, totalValue: totalValueString, hideBalanceStatus: self.viewModel.hideBalanceStatus, shouldShowAction: indexPath.item == 0, isAllChainOverralCell: isAllChainOverallCell)
    
    cell.chainButtonTapped = {
      self.onChainButtonTapped(self.infoCollectionView)
    }
    
    cell.hideBalanceButtonTapped = {
      self.viewModel.hideBalanceStatus = !self.viewModel.hideBalanceStatus
      self.reloadUI()
    }
    
    cell.walletOptionButtonTapped = {
      self.delegate?.overviewMainViewController(self, run: .walletConfig)
      MixPanelManager.track("wallet_details_pop_up_open", properties: ["screenid": "wallet_details_pop_up"])
    }
    
    cell.receiveButtonTapped = {
      self.delegate?.overviewMainViewController(self, run: .receive)
    }
    
    cell.transferButtonTapped = {
      self.delegate?.overviewMainViewController(self, run: .send(recipientAddress: nil))
    }
    
    return cell
  }
}

extension OverviewMainViewController: SkeletonTableViewDataSource, SkeletonTableViewDelegate {
  
  func showLoadingSkeleton() {
    let gradient = SkeletonGradient(baseColor: UIColor.Kyber.cellBackground)
    view.showAnimatedGradientSkeleton(usingGradient: gradient)
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
    return OverviewSkeletonCell.className
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
    let cell = skeletonView.dequeueReusableCell(OverviewSkeletonCell.self, indexPath: indexPath)
    return cell
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
  
}
