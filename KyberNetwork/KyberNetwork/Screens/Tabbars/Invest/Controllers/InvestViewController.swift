//
//  InvestViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/12/21.
//

import UIKit
import FSPagerView
import Kingfisher

class InvestViewModel {
  var dataSource: [Asset] = [] {
    didSet {
      self.bannerDataSource = self.dataSource.filter({ (item) -> Bool in
        return item.type == .banner
      })
      self.partnerDataSource = self.dataSource.filter({ (item) -> Bool in
        return item.type == .partner
      })
    }
  }
  
  var bannerDataSource: [Asset] = []
  var partnerDataSource: [Asset] = []
}

enum InvestViewEvent {
  case openLink(url: String)
  case swap
  case transfer
  case reward
  case krytal
  case dapp
  case multiSend
  case buyCrypto
}

protocol InvestViewControllerDelegate: class {
  func investViewController(_ controller: InvestViewController, run event: InvestViewEvent)
}

class InvestViewController: KNBaseViewController {
  @IBOutlet weak var bannerPagerView: FSPagerView! {
    didSet {
      self.bannerPagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
    }
  }
  @IBOutlet weak var bannerPagerControl: FSPageControl!
  @IBOutlet weak var patnerCollectionView: UICollectionView!
  @IBOutlet weak var collectionViewHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var currentChainIcon: UIImageView!
  
  @IBOutlet weak var buyCryptoView: UIView!
  
  let viewModel: InvestViewModel = InvestViewModel()
  weak var delegate: InvestViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.bannerPagerControl.setFillColor(UIColor(named: "buttonBackgroundColor"), for: .selected)
    self.bannerPagerControl.setFillColor(UIColor(named: "normalTextColor"), for: .normal)
    self.bannerPagerControl.numberOfPages = 0
    self.bannerPagerControl.numberOfPages = self.viewModel.bannerDataSource.count
    let nib = UINib(nibName: MarketingPartnerCollectionViewCell.className, bundle: nil)
    self.patnerCollectionView.register(nib, forCellWithReuseIdentifier: MarketingPartnerCollectionViewCell.cellID)
    self.updateUIBannerPagerView()
    self.updateUIPartnerCollectionView()
    self.updateFeatureFlagChanged()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.bannerPagerView.itemSize = self.bannerPagerView.frame.size
    self.updateUISwitchChain()
    self.configFeatureFlag()
  }
  
  fileprivate func updateFeatureFlagChanged() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(configFeatureFlag),
      name: Notification.Name(kUpdateFeatureFlag),
      object: nil
    )
  }
  
  @objc fileprivate func configFeatureFlag() {
    let shouldShowBuyCrypto = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.bifinityIntegration)
    self.buyCryptoView.subviews.forEach { view in
      view.isHidden = !shouldShowBuyCrypto
    }
    self.buyCryptoView.backgroundColor = shouldShowBuyCrypto ? UIColor(named: "investButtonBgColor")! : .clear
  }
  
  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.chainIconImage
    self.currentChainIcon.image = icon
  }
  
  @IBAction func swapButtonTapped(_ sender: UIButton) {
    self.delegate?.investViewController(self, run: .swap)
  }

  @IBAction func transferButtonTapped(_ sender: UIButton) {
    self.delegate?.investViewController(self, run: .transfer)
  }

  @IBAction func rewardButtonTapped(_ sender: Any) {
    self.delegate?.investViewController(self, run: .reward)
  }

  @IBAction func krytalButtonTapped(_ sender: UIButton) {
    self.delegate?.investViewController(self, run: .krytal)
  }
  
  @IBAction func dAppButtonTapped(_ sender: UIButton) {
    self.delegate?.investViewController(self, run: .dapp)
  }

  @IBAction func buyCryptoButtonTapped(_ sender: Any) {
    self.delegate?.investViewController(self, run: .buyCrypto)
  
  @IBAction func multiSendButtonTapped(_ sender: UIButton) {
    self.delegate?.investViewController(self, run: .multiSend)
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

  func coordinatorDidUpdateMarketingAssets(_ assets: [Asset]) {
    self.viewModel.dataSource = assets
    guard self.isViewLoaded else { return }
    self.updateUIBannerPagerView()
    self.updateUIPartnerCollectionView()
  }
  
  fileprivate func updateUIPartnerCollectionView() {
    self.patnerCollectionView.reloadData()
    self.collectionViewHeightContraint.constant = CGFloat( (round(CGFloat(self.viewModel.partnerDataSource.count / 3)) + 1) * MarketingPartnerCollectionViewCell.kMarketingPartnerCellHeight) + 50
  }
  
  fileprivate func updateUIBannerPagerView() {
    self.bannerPagerControl.numberOfPages = self.viewModel.bannerDataSource.count
    self.bannerPagerView.reloadData()
  }
  
  func coordinatorDidUpdateChain() {
    guard self.isViewLoaded else {
      return
    }
    self.updateUISwitchChain()
  }
}

extension InvestViewController: FSPagerViewDataSource {
  public func numberOfItems(in pagerView: FSPagerView) -> Int {
    return self.viewModel.bannerDataSource.count
  }

  public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
    let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
    let url = URL(string: self.viewModel.bannerDataSource[index].imageURL)
    cell.imageView?.kf.setImage(with: url)
    cell.imageView?.contentMode = .scaleAspectFit
    cell.imageView?.clipsToBounds = true
    return cell
  }
}

extension InvestViewController: FSPagerViewDelegate {
  func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
    pagerView.deselectItem(at: index, animated: true)
    pagerView.scrollToItem(at: index, animated: true)
    self.delegate?.investViewController(self, run: .openLink(url: self.viewModel.bannerDataSource[index].url))
  }

  func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
    self.bannerPagerControl.currentPage = targetIndex
  }

  func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
    self.bannerPagerControl.currentPage = pagerView.currentIndex
  }
}

extension InvestViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 12.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let cellWidth = (collectionView.frame.size.width - 24) / 3
    return CGSize(
      width: cellWidth,
      height: MarketingPartnerCollectionViewCell.kMarketingPartnerCellHeight
    )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: 0,
      height: 0
    )
  }
}

extension InvestViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.partnerDataSource.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
    withReuseIdentifier: MarketingPartnerCollectionViewCell.cellID,
    for: indexPath
    ) as! MarketingPartnerCollectionViewCell
    let url = URL(string: self.viewModel.partnerDataSource[indexPath.row].imageURL)
    cell.bannerImageView.kf.setImage(with: url)
    cell.bannerImageView.clipsToBounds = true
    return cell
  }
}

extension InvestViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.delegate?.investViewController(self, run: .openLink(url: self.viewModel.partnerDataSource[indexPath.row].url))
  }
}
