//
//  OverviewBrowsingViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 05/09/2022.
//

import UIKit
import BaseModule

protocol OverviewBrowsingViewControllerDelegate: class {
  func didSelectSearch(_ controller: OverviewBrowsingViewController)
  func didSelectNotification(_ controller: OverviewBrowsingViewController)
  func didSelectToken(_ controller: OverviewBrowsingViewController, token: Token)
}

class OverviewBrowsingViewModel {
  var displayHeader: ThreadProtectedObject<[SectionKeyType]> = .init(storageValue: [])
  var dataSource: ThreadProtectedObject<[String: [OverviewMainCellViewModel]]> = .init(storageValue: [:])
  var marketSortType: MarketSortType = .ch24(des: true)
  var currencyMode: CurrencyMode
  var rightMode: RightMode = .value

  init() {
    if let savedCurrencyMode = CurrencyMode(rawValue: UserDefaults.standard.integer(forKey: Constants.currentCurrencyMode)) {
      self.currencyMode = savedCurrencyMode.isQuoteCurrency ? KNGeneralProvider.shared.quoteCurrency : savedCurrencyMode
    } else {
      self.currencyMode = .usd
    }
  }
  
  func getViewModelsForSection(_ section: Int) -> [OverviewMainCellViewModel] {
    guard !self.displayHeader.value.isEmpty else {
      return self.dataSource.value[""] ?? []
    }
    
    let key = self.displayHeader.value[section]
    return self.dataSource.value[key.toString()] ?? []
  }

  func reloadAllData() {
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
      return OverviewMainCellViewModel(mode: .market(token: item, rightMode: rightMode), currency: self.currencyMode)
    }
    self.dataSource.value = ["": models]
  }
  
  func numberOfRowsInSection(section: Int) -> Int {
    return self.getViewModelsForSection(section).count
  }
}

class OverviewBrowsingViewController: InAppBrowsingViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet var sortButtons: [UIButton]!
  @IBOutlet weak var sortMarketByCh24Button: UIButton!
  @IBOutlet weak var rightModeSortLabel: UILabel!
  let viewModel: OverviewBrowsingViewModel
  weak var delegate: OverviewBrowsingViewControllerDelegate?
  init(viewModel: OverviewBrowsingViewModel) {
    self.viewModel = viewModel
    super.init(nibName: OverviewBrowsingViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.registerCellNib(OverviewMainViewCell.self)
    reloadUI()
  }
  
  func reloadUI() {
    guard isViewLoaded else { return }
    self.updateUISortBar()
    self.updateCh24Button()
    self.viewModel.reloadAllData()
    self.tableView.reloadData()
  }
  
  override func reloadChainData() {
    reloadUI()
  }
  
  fileprivate func updateCh24Button() {
    switch self.viewModel.rightMode {
    case .ch24:
      self.sortMarketByCh24Button.tag = 2
      self.rightModeSortLabel.text = "24h"
    default:
      self.sortMarketByCh24Button.tag = 5
      self.rightModeSortLabel.text = "Cap"
    }
  }
  
  override func handleAddWalletTapped() {
    super.handleAddWalletTapped()
    MixPanelManager.track("home_connect_wallet", properties: ["screenid": "homepage"])
  }
  
  @IBAction func searchButtonTapped(_ sender: UIButton) {
    self.delegate?.didSelectSearch(self)
    MixPanelManager.track("home_search", properties: ["screenid": "homepage"])
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
  
  fileprivate func updateUIForIndicatorView(button: UIButton, dec: Bool) {
    if dec {
      let img = UIImage(named: "sort_down_icon")
      button.setImage(img, for: .normal)
    } else {
      let img = UIImage(named: "sort_up_icon")
      button.setImage(img, for: .normal)
    }
  }

}
extension OverviewBrowsingViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRowsInSection(section: section)
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(OverviewMainViewCell.self, indexPath: indexPath)!
    if let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[safe: indexPath.row] {
      cell.updateCell(cellModel)
    }

    cell.action = {
      self.viewModel.rightMode = self.viewModel.rightMode == .value ? .ch24 : .value
      self.reloadUI()
    }
    return cell
  }
}

extension OverviewBrowsingViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return OverviewMainViewCell.kCellHeight
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[safe: indexPath.row] {
      switch cellModel.mode {
      case .market(token: let token, _):
        self.delegate?.didSelectToken(self, token: token)
      default:
        return
      }
    }
    
  }
}
