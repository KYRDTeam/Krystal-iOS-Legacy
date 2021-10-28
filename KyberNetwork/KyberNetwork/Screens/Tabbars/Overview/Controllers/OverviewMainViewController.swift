//
//  OverviewMainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/9/21.
//

import UIKit
import BigInt
import SwipeCellKit

protocol OverviewMainViewControllerDelegate: class {
  func overviewMainViewController(_ controller: OverviewMainViewController, run event: OverviewMainViewEvent)
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
  @IBOutlet weak var filterSectionViewHeight: NSLayoutConstraint!
  @IBOutlet weak var totalBalanceContainerViewHeight: NSLayoutConstraint!
  @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
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

    let nibLiquidityPool = UINib(nibName: OverviewLiquidityPoolCell.className, bundle: nil)
    self.tableView.register(
      nibLiquidityPool,
      forCellReuseIdentifier: OverviewLiquidityPoolCell.kCellID
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
    self.delegate?.overviewMainViewController(self, run: .didAppear)
  }

  fileprivate func updateUIHideBalanceButton() {
    self.hideBalanceButton.setImage(self.viewModel.displayHideBalanceImage, for: .normal)
  }
  
  fileprivate func updateUIWalletList() {
    self.walletNameLabel.text = self.viewModel.session.wallet.getWalletObject()?.name ?? "---"
  }

  fileprivate func reloadUI(_ animation: UIView.AnimationOptions = .transitionFlipFromLeft) {
    self.viewModel.reloadAllData()
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.currentPageNameLabel.text = self.viewModel.displayCurrentPageName
    self.updateUIHideBalanceButton()
    self.sortingContainerView.isHidden = self.viewModel.currentMode != .market(rightMode: .ch24)
    DispatchQueue.main.async {
      self.filterSectionViewHeight.constant = self.viewModel.currentMode != .market(rightMode: .ch24) ? 60 : 96
      self.tableViewTopConstraint.constant = self.viewModel.currentMode != .market(rightMode: .ch24) ? 60 : 96
    }
    
    self.updateUIWalletList()
    self.updateCh24Button()
    UIView.transition(with: self.tableView, duration: 0.35, options: animation) {
      self.tableView.reloadData()
    }
    
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
    self.reloadUI(.transitionCrossDissolve)
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
    return self.viewModel.numberOfRowsInSection(section: section)
  }

  func emptyCell(indexPath: IndexPath) -> OverviewEmptyTableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewEmptyTableViewCell.kCellID,
      for: indexPath
    ) as! OverviewEmptyTableViewCell
    switch self.viewModel.currentMode {
    case .asset:
      cell.imageIcon.image = UIImage(named: "empty_asset_icon")
      cell.titleLabel.text = "Your balance is empty"
      cell.button1.isHidden = KNGeneralProvider.shared.currentChain != .eth
      cell.button1.setTitle("+ Buy ETH", for: .normal)
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
    case .showLiquidityPool:
      cell.imageIcon.image = UIImage(named: "liquidity_pool_empty_icon")
      cell.titleLabel.text = "You don't have any liquidity pool".toBeLocalised()
      cell.button1.isHidden = true
      cell.button2.isHidden = true
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

  func tokenInfoCell(indexPath: IndexPath) -> OverviewMainViewCell {
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
    cell.delegate = self
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

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard !self.viewModel.isEmpty() else {
      return emptyCell(indexPath: indexPath)
    }
    
    switch self.viewModel.currentMode {
    case .asset:
        let isLastCell = indexPath.row == self.viewModel.numberOfRowsInSection(section: indexPath.section) - 1
        return isLastCell ? showOrHideSmallValueTokenCell() : tokenInfoCell(indexPath: indexPath)
    case .market, .favourite:
        return tokenInfoCell(indexPath: indexPath)
    case .supply:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewDepositTableViewCell.kCellID,
        for: indexPath
      ) as! OverviewDepositTableViewCell
      let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
      cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
      cell.updateCell(cellModel)
      return cell
    case .showLiquidityPool:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewLiquidityPoolCell.kCellID,
        for: indexPath
      ) as! OverviewLiquidityPoolCell
        let key = self.viewModel.displayHeader[indexPath.section]
        if let viewModel = self.viewModel.displayLPDataSource[key]?[indexPath.row] {
          viewModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
          cell.updateCell(viewModel)
        }
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
    
    guard self.viewModel.currentMode == .supply || self.viewModel.currentMode == .nft || self.viewModel.currentMode == .showLiquidityPool else {
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
      let rightTextString = self.viewModel.getTotalValueForSection(section)
      let rightLabelWidth = rightTextString.width(withConstrainedHeight: 40, font: UIFont.Kyber.regular(with: 18))
      
      
      let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: tableView.frame.size.width - rightLabelWidth - 70, height: 40))
      titleLabel.center.y = view.center.y
      titleLabel.text = self.viewModel.displayHeader[section]
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

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    guard self.viewModel.currentMode == .supply || self.viewModel.currentMode == .nft || self.viewModel.currentMode == .showLiquidityPool else {
      return 0.01
    }
    return 40
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
      self.reloadUI(.transitionCrossDissolve)
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
    case.showLiquidityPool:
        return OverviewLiquidityPoolCell.kCellHeight
    case .nft:
      return OverviewNFTTableViewCell.kCellHeight
    }
  }
}

extension OverviewMainViewController: UIScrollViewDelegate {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let alpha = scrollView.contentOffset.y <= 0 ? pow(abs(scrollView.contentOffset.y) / 200.0, 4)  : 0.0
    self.totalBalanceContainerView.alpha = alpha
    self.totalBalanceContainerViewHeight.constant = scrollView.contentOffset.y <= 0 ? abs(scrollView.contentOffset.y) - 10 : 0
  }
}

extension OverviewMainViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else {
      return nil
    }

    switch self.viewModel.currentMode {
    case .asset:
      let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
      guard let token = KNSupportedTokenStorage.shared.getTokenWith(symbol: cellModel.tokenSymbol) else { return nil }
      // hide action
      let hideAction = SwipeAction(style: .default, title: nil) { _, _ in
        KNSupportedTokenStorage.shared.setTokenActiveStatus(token: token, status: false)
        let params: [String : Any] = [
          "token_name": token.name,
          "token_address": token.address,
          "token_disable": true,
          "screen_name": "OverviewMainViewController",
        ]
        KNCrashlyticsUtil.logCustomEvent(withName: "token_change_disable", customAttributes: params)
        self.reloadUI()
      }
      hideAction.title = "Hide".toBeLocalised().uppercased()
      hideAction.textColor = UIColor(named: "normalTextColor")
      hideAction.font = UIFont.Kyber.medium(with: 12)
      let bgImg = UIImage(named: "history_cell_edit_bg")!
      let resized = bgImg.resizeImage(to: CGSize(width: 104, height: OverviewMainViewCell.kCellHeight))!
      hideAction.backgroundColor = UIColor(patternImage: resized)

      // soft delete action for custom token
      let deleteAction = SwipeAction(style: .default, title: nil) { _, _ in
        KNSupportedTokenStorage.shared.deleteCustomToken(token)
        let params: [String : Any] = [
          "token_name": token.name,
          "token_address": token.address,
          "screen_name": "OverviewMainViewController",
        ]
        KNCrashlyticsUtil.logCustomEvent(withName: "token_delete", customAttributes: params)
        self.reloadUI()
      }
      deleteAction.title = "Delete".toBeLocalised().uppercased()
      deleteAction.textColor = UIColor(named: "normalTextColor")
      deleteAction.font = UIFont.Kyber.medium(with: 12)
      deleteAction.backgroundColor = UIColor(patternImage: resized)
      
      if KNSupportedTokenStorage.shared.getActiveCustomToken().contains(token) {
        return [hideAction, deleteAction]
      }
      return [hideAction]
    default:
      return nil
    }
  }

  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.transitionStyle = .reveal
    options.backgroundColor = UIColor(named: "mainViewBgColor")
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90
    return options
  }
}
