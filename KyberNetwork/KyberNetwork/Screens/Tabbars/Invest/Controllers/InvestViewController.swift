//
//  InvestViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/12/21.
//

import UIKit
import Kingfisher
import KrystalWallets
import BaseModule

enum InvestViewEvent {
  case openLink(url: String)
  case swap
  case transfer
  case reward
  case krytal
  case dapp
  case multiSend
  case promoCode
  case buyCrypto
  case rewardHunting
  case bridge
  case scanner
  case stake
    case openApprovals
}

protocol InvestViewControllerDelegate: class {
  func investViewController(_ controller: InvestViewController, run event: InvestViewEvent)
}

class InvestViewController: InAppBrowsingViewController {
  @IBOutlet weak var collectionView: UICollectionView!
  
  let viewModel: ExploreViewModel = ExploreViewModel()
  weak var delegate: InvestViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tabBarItem.accessibilityIdentifier = "menuExplore"
    
    self.setupCollectionView()
    self.bindViewModel()
    self.viewModel.onViewLoaded()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.viewModel.reloadMenuItems()
    MixPanelManager.track("explore_open", properties: ["screenid": "explore"])
  }
  
  func setupCollectionView() {
    collectionView.registerCellNib(MarketingPartnerCollectionViewCell.self)
    collectionView.registerCellNib(ExploreBannersCell.self)
    collectionView.registerCellNib(ExploreMenuCell.self)
    collectionView.registerHeaderCellNib(ExploreSectionHeaderView.self)
    collectionView.contentInset.bottom = 36
    
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  override func reloadWallet() {
    super.reloadWallet()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.viewModel.reloadMenuItems()
      self.collectionView.reloadData()
    }
  }
  
  func bindViewModel() {
    viewModel.banners.bind { [weak self] _ in
      self?.reloadSection(ofType: .banners)
    }
    viewModel.menuItems.bind { [weak self] _ in
      self?.reloadSection(ofType: .menu)
    }
    viewModel.partners.bind { [weak self] _ in
      self?.reloadSection(ofType: .partners)
    }
  }
  
  private func reloadSection(ofType type: ExploreSection) {
    guard let index = viewModel.sections.index(of: type) else { return }
    collectionView.reloadSections(.init(arrayLiteral: index))
  }
  
  override func handleWalletButtonTapped() {
    super.handleWalletButtonTapped()
    MixPanelManager.track("xplore_select_wallet", properties: ["screenid": "explore"])
  }
  
  func coordinatorDidUpdateMarketingAssets(_ assets: [Asset]) {
    self.viewModel.partners.value = assets.filter { $0.type == .partner }
    self.viewModel.banners.value = assets.filter { $0.type == .banner }
  }
  
  func coordinatorDidUpdateChain() {
    guard self.isViewLoaded else {
      return
    }
    self.viewModel.reloadMenuItems()
  }
  
  func coordinatorDidSwitchAddress() {
    self.viewModel.reloadMenuItems()
  }
  
  override func handleAddWalletTapped() {
    super.handleAddWalletTapped()
    MixPanelManager.track("explore_connect_wallet", properties: ["screenid": "explore"])
  }
  
}

extension InvestViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 12.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 6, left: 20, bottom: 6, right: 20)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let sectionType = viewModel.sections[indexPath.section]
    
    switch sectionType {
    case .banners:
      return .init(width: collectionView.frame.width, height: 240)
    case .menu:
      let cellWidth = (collectionView.frame.size.width - 76) / 4
      return .init(width: cellWidth, height: cellWidth)
    case .partners:
      let cellWidth = (collectionView.frame.size.width - 64) / 3
      return CGSize(
        width: cellWidth,
        height: MarketingPartnerCollectionViewCell.kMarketingPartnerCellHeight
      )
    }
  }
  
}

extension InvestViewController: UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return viewModel.sections.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionType = viewModel.sections[section]
    switch sectionType {
    case .banners:
      return 1
    case .menu:
      return viewModel.menuItems.value.count
    case .partners:
      return viewModel.partners.value.count
    }
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let sectionType = viewModel.sections[indexPath.section]
    
    switch sectionType {
    case .banners:
      let cell = collectionView.dequeueReusableCell(ExploreBannersCell.self, indexPath: indexPath)!
      cell.configure(banners: viewModel.banners.value)
      cell.onSelectBanner = { [weak self] asset in
        guard let self = self else { return }
        self.delegate?.investViewController(self, run: .openLink(url: asset.url))
      }
      return cell
    case .menu:
      let cell = collectionView.dequeueReusableCell(ExploreMenuCell.self, indexPath: indexPath)!
      let item = ExploreMenuItemViewModel(item: viewModel.menuItems.value[indexPath.item])
      cell.configure(item: item)
      return cell
    case .partners:
      let cell = collectionView.dequeueReusableCell(MarketingPartnerCollectionViewCell.self, indexPath: indexPath)!
      cell.configure(asset: viewModel.partners.value[indexPath.item])
      return cell
    }
  }
}

extension InvestViewController: UICollectionViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    let sectionType = viewModel.sections[indexPath.section]
    
    switch sectionType {
    case .partners:
      if kind == UICollectionView.elementKindSectionHeader {
        let header = collectionView.dequeueReusableHeaderCell(ExploreSectionHeaderView.self, indexPath: indexPath)!
        header.configure(title: Strings.supportedPlatforms)
        return header
      }
      return UICollectionReusableView()
    default:
      return UICollectionReusableView()
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    let sectionType = viewModel.sections[section]
    
    switch sectionType {
    case .partners:
      return .init(width: collectionView.frame.width, height: 56)
    default:
      return .zero
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let sectionType = viewModel.sections[indexPath.section]

    switch sectionType {
    case .menu:
      let menuItem = viewModel.menuItems.value[indexPath.item]
      switch menuItem {
      case .swap:
        delegate?.investViewController(self, run: .swap)
        MixPanelManager.track("Xplore_swap", properties: ["screenid": "explore"])
      case .transfer:
        delegate?.investViewController(self, run: .transfer)
        MixPanelManager.track("Xplore_transfer", properties: ["screenid": "explore"])
      case .reward:
        delegate?.investViewController(self, run: .reward)
        MixPanelManager.track("Xplore_reward", properties: ["screenid": "explore"])
      case .referral:
        delegate?.investViewController(self, run: .krytal)
        MixPanelManager.track("Xplore_referral", properties: ["screenid": "explore"])
      case .dapps:
        delegate?.investViewController(self, run: .dapp)
        MixPanelManager.track("Xplore_dapps", properties: ["screenid": "explore"])
      case .multisend:
        delegate?.investViewController(self, run: .multiSend)
        MixPanelManager.track("Xplore_multisend", properties: ["screenid": "explore"])
      case .buyCrypto:
        delegate?.investViewController(self, run: .buyCrypto)
        MixPanelManager.track("Xplore_buy_cryto", properties: ["screenid": "explore"])
      case .promotion:
        delegate?.investViewController(self, run: .promoCode)
        MixPanelManager.track("Xplore_promotion", properties: ["screenid": "explore"])
      case .rewardHunting:
        delegate?.investViewController(self, run: .rewardHunting)
        MixPanelManager.track("Xplore_reward_hunting", properties: ["screenid": "explore"])
      case .bridge:
        delegate?.investViewController(self, run: .bridge)
        MixPanelManager.track("Xplore_Krystal_bridge", properties: ["screenid": "explore"])
      case .scanner:
        delegate?.investViewController(self, run: .scanner)
        MixPanelManager.track("Xplore_Scanner", properties: ["screenid": "explore"])
      case .approvals:
          delegate?.investViewController(self, run: .openApprovals)
      }
    case .partners:
      let partner = viewModel.partners.value[indexPath.item]
      self.delegate?.investViewController(self, run: .openLink(url: partner.url))
    default:
      ()
    }
  }
}
