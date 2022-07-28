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

protocol OverviewMainViewControllerDelegate: class {
  func overviewMainViewController(_ controller: OverviewMainViewController, run event: OverviewMainViewEvent)
}

class OverviewMainViewController: KNBaseViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var totalBalanceContainerView: UIView!
  @IBOutlet weak var notificationButton: UIButton!
  @IBOutlet weak var searchButton: UIButton!
  @IBOutlet weak var totalPageValueLabel: UILabel!
  @IBOutlet weak var currentPageNameLabel: UILabel!
  @IBOutlet weak var currentChainIcon: UIImageView!
  @IBOutlet weak var currentChainLabel: UILabel!
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
  
  weak var delegate: OverviewMainViewControllerDelegate?
  let refreshControl = UIRefreshControl()
  let viewModel: OverviewMainViewModel
  let calculatingQueue = DispatchQueue.global()
  
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
      case .market:
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
//    let isAdvancedSearchEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.advancedSearch)
//    self.searchButton.isHidden = !isAdvancedSearchEnabled
    let nib = UINib(nibName: OverviewMainViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewMainViewCell.kCellID
    )
    
    self.tableView.registerCellNib(OverviewAllChainTokenCell.self)
    
    let nibSupply = UINib(nibName: OverviewDepositTableViewCell.className, bundle: nil)
    self.tableView.register(
      nibSupply,
      forCellReuseIdentifier: OverviewDepositTableViewCell.kCellID
    )
    
    let nibLiquidityPool = UINib(nibName: OverviewLiquidityPoolCell.className, bundle: nil)
    self.tableView.register(
      nibLiquidityPool,
      forCellReuseIdentifier: OverviewLiquidityPoolCell.kCellID
    )
    
    self.tableView.registerCellNib(OverviewMultichainLiquidityPoolCell.self)
    
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
    
    let nibSummary = UINib(nibName: OverviewSummaryCell.className, bundle: nil)
    self.tableView.register(
      nibSummary,
      forCellReuseIdentifier: OverviewSummaryCell.kCellID
    )
    
    let infoNib = UINib(nibName: OverviewTotalInfoCell.className, bundle: nil)
    self.infoCollectionView.register(infoNib, forCellWithReuseIdentifier: OverviewTotalInfoCell.cellID)
    
    self.setupViews()
    self.configPullToRefresh()
    self.configHeaderTapped()
  }
  
  func setupViews() {
    scanButton.isHidden = false // !FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.scanner)
  }
  
  func configHeaderTapped() {
    self.viewModel.didTapAddNFTHeader = {
      self.delegate?.overviewMainViewController(self, run: .addNFT)
    }
    
    self.viewModel.didTapSectionButtonHeader = { sender in
      print("Button Clicked \(sender.tag)")
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
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUISwitchChain()
    self.delegate?.overviewMainViewController(self, run: .didAppear)
  }
  
  fileprivate func reloadUI() {
    calculatingQueue.async {
      self.viewModel.reloadAllData()
      DispatchQueue.main.async {
        self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
        self.currentPageNameLabel.text = self.viewModel.displayCurrentPageName
        self.sortingContainerView.isHidden = self.viewModel.currentMode != .market(rightMode: .ch24) || self.viewModel.overviewMode == .summary
        self.totatlInfoView.isHidden = self.viewModel.overviewMode == .summary
        self.insestView.frame.size.height = self.insetViewHeight
        self.updateCh24Button()
        self.tableView.reloadData()
        self.infoCollectionView.reloadData()
      }
    }
    
  }
  
  fileprivate func updateUISwitchChain() {
    let selected = self.viewModel.currentChain
    self.currentChainIcon.image = selected.chainIcon()
    self.currentChainLabel.text = selected.chainName()
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
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController(includedAll: true, selected: self.viewModel.currentChain)
    popup.completionHandler = { [weak self] selected in
      guard let self = self else { return }
      guard selected != .all else {
        self.viewModel.currentChain = selected
        self.updateUISwitchChain()
//        self.tableView.reloadData()
        self.delegate?.overviewMainViewController(self, run: .selectAllChain)
        return
      }
      
      let addresses = WalletManager.shared.getAllAddresses(addressType: selected.addressType)
      if addresses.isEmpty {
        self.delegate?.overviewMainViewController(self, run: .addChainWallet(chain: selected))
        return
      } else {
        let viewModel = SwitchChainWalletsListViewModel(selected: selected)
        let secondPopup = SwitchChainWalletsListViewController(viewModel: viewModel)
        self.present(secondPopup, animated: true, completion: nil)
      }
    }
    self.present(popup, animated: true, completion: nil)
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
    self.delegate?.overviewMainViewController(self, run: .notifications)
  }
  
  @IBAction func searchButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .search)
  }
  
  @IBAction func scanWasTapped(_ sender: Any) {
    guard let nav = self.navigationController else { return }
    
    var acceptedResultTypes: [ScanResultType] = []
    var scanModes: [ScanMode] = [.qr, .text]
    if KNGeneralProvider.shared.currentChain.isEVM {
      acceptedResultTypes.append(contentsOf: [.walletConnect, .ethPublicKey, .ethPrivateKey])
      scanModes = [.qr, .text]
    } else if KNGeneralProvider.shared.currentChain == .solana {
      acceptedResultTypes.append(contentsOf: [.solPublicKey, .solPrivateKey])
      scanModes = [.qr]
    }
    
    ScannerModule.start(navigationController: nav, acceptedResultTypes: acceptedResultTypes, scanModes: scanModes) { [weak self] text, type in
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
      }
    }
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
  
  func coordinatorAppSwitchAddress() {
    self.viewModel.currentChain = KNGeneralProvider.shared.currentChain
    guard self.isViewLoaded else { return }
    calculatingQueue.async {
      self.viewModel.reloadAllData()
      DispatchQueue.main.async {
        self.updateUISwitchChain()
        self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
        self.tableView.reloadData()
        self.infoCollectionView.reloadData()
      }
    }
  }
  
  func coordinatorDidUpdateDidUpdateTokenList() {
    guard self.isViewLoaded else { return }
    calculatingQueue.async {
      self.viewModel.reloadAllData()
      DispatchQueue.main.async {
        self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
        self.tableView.reloadData()
        self.infoCollectionView.reloadData()
      }
    }
  }
  
  func coordinatorDidUpdateCurrencyMode(_ mode: CurrencyMode) {
    self.viewModel.updateCurrencyMode(mode: mode)
    self.reloadUI()
  }
  
  func coordinatorPullToRefreshDone() {
    self.viewModel.isRefreshingTableView = false
    DispatchQueue.main.async {
      self.refreshControl.endRefreshing()
    }
  }
  
  func coordinatorDidUpdateAllTokenData(models: [ChainBalanceModel]) {
    self.viewModel.assetChainBalanceModels = models
    self.reloadUI()
  }
  
  func coordinatorDidUpdateAllLPData(models: [ChainLiquidityPoolModel]) {
    self.viewModel.chainLiquidityPoolModels = models
    self.reloadUI()
  }
  
  func overviewModeDidChanged(isSummary: Bool) {
    self.viewModel.overviewMode = isSummary ? .summary : .overview
    self.sortingContainerView.isHidden = self.viewModel.currentMode != .market(rightMode: .ch24) || self.viewModel.overviewMode == .summary
    self.totatlInfoView.isHidden = self.viewModel.overviewMode == .summary
    self.tableViewTopConstraint.constant = 0
    self.insestView.frame.size.height = insetViewHeight
    self.tableView.reloadData()
    self.configPullToRefresh()
  }
  
  static var hasSafeArea: Bool {
    guard #available(iOS 11.0, *), let topPadding = UIApplication.shared.keyWindow?.safeAreaInsets.top, topPadding > 24 else {
      return false
    }
    return true
  }
}

extension OverviewMainViewController: UITableViewDataSource {
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
      cell.button1.isHidden = !FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.bifinityIntegration)
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
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewSummaryCell.kCellID,
      for: indexPath
    ) as! OverviewSummaryCell
    
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
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewDepositTableViewCell.kCellID,
        for: indexPath
      ) as! OverviewDepositTableViewCell
      if let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[safe: indexPath.row] {
        cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
        cell.updateCell(cellModel)
      }
      
      return cell
    case .showLiquidityPool:
      if self.viewModel.currentChain == .all {
        let cell = tableView.dequeueReusableCell(OverviewMultichainLiquidityPoolCell.self, indexPath: indexPath)!
        let key = self.viewModel.displayHeader.value[indexPath.section]
        if let viewModel = self.viewModel.displayLPDataSource.value[key.0 + (key.1?.chainName() ?? "")]?[indexPath.row] {
          viewModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
          cell.updateCell(viewModel)
        }
        return cell
      }
        
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewLiquidityPoolCell.kCellID,
        for: indexPath
      ) as! OverviewLiquidityPoolCell
      let key = self.viewModel.displayHeader.value[indexPath.section]
      if let viewModel = self.viewModel.displayLPDataSource.value[key.0 + (key.1?.chainName() ?? "")]?[indexPath.row] {
        viewModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
        cell.updateCell(viewModel)
      }
      return cell
    case .nft:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewNFTTableViewCell.kCellID,
        for: indexPath
      ) as! OverviewNFTTableViewCell
      let key = self.viewModel.displayNFTHeader.value[indexPath.section].collectibleName
      if let viewModel = self.viewModel.displayNFTDataSource.value[key]?[indexPath.row] {
        cell.updateCell(viewModel)
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
        guard self.viewModel.getChainForSection(indexPath.section) == KNGeneralProvider.shared.currentChain else {
          if let chain = self.viewModel.getChainForSection(indexPath.section) {
            self.showSwitchChainAlert(chain)
          }
          return
        }
        let platform = self.viewModel.displayHeader.value[indexPath.section]
        self.delegate?.overviewMainViewController(self, run: .withdrawBalance(platform: platform.0, balance: lendingBalance))
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        guard distributionBalance.chainType == KNGeneralProvider.shared.currentChain else {
          if let chain = distributionBalance.chainType {
            self.showSwitchChainAlert(chain)
          }
          return
        }
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
      }
    } else {
      DispatchQueue.main.async {
        self.infoCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
        self.overviewModeDidChanged(isSummary: false)
      }
    }
  }
  
}

extension OverviewMainViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 2
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: OverviewTotalInfoCell.cellID,
      for: indexPath
    ) as! OverviewTotalInfoCell
    
    var totalValueString = ""
    if indexPath.row == 0 && self.viewModel.currentChain != .all {
      totalValueString = self.viewModel.displayTotalValue
    } else {
      totalValueString = self.viewModel.displayTotalSummaryValue
    }
    
    cell.updateCell(walletName: viewModel.currentWalletName, totalValue: totalValueString, hideBalanceStatus: self.viewModel.hideBalanceStatus, shouldShowAction: indexPath.item == 0)
    
    cell.walletListButtonTapped = {
      self.delegate?.overviewMainViewController(self, run: .selectListWallet)
    }
    
    cell.hideBalanceButtonTapped = {
      self.viewModel.hideBalanceStatus = !self.viewModel.hideBalanceStatus
      self.reloadUI()
    }
    
    cell.walletOptionButtonTapped = {
      self.delegate?.overviewMainViewController(self, run: .walletConfig)
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
