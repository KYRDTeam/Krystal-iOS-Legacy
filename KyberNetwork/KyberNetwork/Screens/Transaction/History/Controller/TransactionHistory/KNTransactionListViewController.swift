//
//  KNTransactionListViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import UIKit
import SwipeCellKit
import SkeletonView

protocol KNTransactionListViewControllerDelegate: AnyObject {
  func selectSwapNow(_ viewController: KNTransactionListViewController)
  func transactionListViewController(_ viewController: KNTransactionListViewController, openDetail transaction: TransactionHistoryItem)
}

class KNTransactionListViewController: BaseTransactionListViewController {
  
  @IBOutlet weak var collectionView: UICollectionView!
  
  var viewModel: BaseTransactionListViewModel!
  weak var delegate: KNTransactionListViewControllerDelegate?
  var animatingCell: UICollectionViewCell?
  private let refreshControl = UIRefreshControl()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCollectionView()
    bindViewModel()
    startSkeletonAnimation()
    reload()
  }
  
  func setupCollectionView() {
    self.collectionView.registerCellNib(KNHistoryTransactionCollectionViewCell.self)
    self.collectionView.registerCell(LoadingIndicatorCell.self)
    self.collectionView.registerCellNib(TransactionListEmptyCell.self)
    self.collectionView.registerHeaderCellNib(KNTransactionCollectionReusableView.self)
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.collectionView.refreshControl = self.refreshControl
    self.refreshControl.tintColor = .lightGray
    self.refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
  }
  
  func bindViewModel() {
    viewModel.groupedTransactions.observe(on: self) { [weak self] _ in
      DispatchQueue.main.async {
        self?.reloadUI()
      }
    }
  }
  
  func startSkeletonAnimation() {
    let gradient = SkeletonGradient(baseColor: UIColor.Kyber.dark)
    let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight)
    view.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
  }
  
  func reloadUI() {
    collectionView?.reloadData()
    view.hideSkeleton()
    refreshControl.endRefreshing()
  }
  
  @IBAction func swapWasTapped(_ sender: Any) {
    delegate?.selectSwapNow(self)
  }
  
  @objc private func refreshData(_ sender: Any) {
    guard self.refreshControl.isRefreshing else {
      return
    }
    self.reload()
  }
  
  override func updateWallet(wallet: KNWalletObject) {
    startSkeletonAnimation()
    DispatchQueue.global().async {
      self.viewModel.updateWallet(wallet: wallet)
    }
  }
  
  override func reload() {
    DispatchQueue.global().async {
      self.viewModel.reload()
    }
  }
  
}

extension KNTransactionListViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNHistoryTransactionCollectionViewCell.height
    )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    if viewModel.isTransactionListEmpty {
      return .zero
    }
    return CGSize(width: collectionView.frame.width, height: 24)
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if viewModel.isLoading || !viewModel.canLoadMore { return }
    if indexPath.section == viewModel.numberOfSections - 1 && indexPath.item == viewModel.numberOfItems(inSection: indexPath.section) - 1 {
      DispatchQueue.global().async {
        self.viewModel.load()
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard !transactionsIsEmpty else {
      return
    }
    guard indexPath.section < viewModel.numberOfSections else {
      return
    }
    guard let transaction = viewModel.item(forIndex: indexPath.item, inSection: indexPath.section) else {
      return
    }
    delegate?.transactionListViewController(self, openDetail: transaction)
  }
}

extension KNTransactionListViewController {
  
  var transactionsIsEmpty: Bool {
    return viewModel.isTransactionListEmpty && !viewModel.isLoading
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    if transactionsIsEmpty {
      return 1
    }
    return viewModel.numberOfSections
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if transactionsIsEmpty {
      return 1
    }
    if section < viewModel.numberOfSections - 1 {
      return viewModel.numberOfItems(inSection: section)
    }
    return viewModel.numberOfItems(inSection: section) + (viewModel.canLoadMore ? 1 : 0) // For load more indicator
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard !viewModel.isTransactionListEmpty else {
      let cell = collectionView.dequeueReusableCell(TransactionListEmptyCell.self, indexPath: indexPath)!
      cell.frame = collectionView.frame
      return cell
    }
    let isLastSection = indexPath.section == viewModel.numberOfSections - 1
    let isLastCell = indexPath.item == viewModel.numberOfItems(inSection: indexPath.section)
    if isLastSection && isLastCell {
      let cell = collectionView.dequeueReusableCell(LoadingIndicatorCell.self, indexPath: indexPath)!
      cell.inidicator.startAnimating()
      return cell
    } else {
      let cell = collectionView.dequeueReusableCell(KNHistoryTransactionCollectionViewCell.self, indexPath: indexPath)!
      if let item = viewModel.item(forIndex: indexPath.item, inSection: indexPath.section) {
        let viewModel = item.toViewModel()
        cell.updateCell(with: viewModel, index: indexPath.item)
      }
      return cell
    }
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionView.elementKindSectionHeader:
      let headerView = collectionView.dequeueReusableHeaderCell(KNTransactionCollectionReusableView.self, indexPath: indexPath)!
      headerView.updateView(with: self.viewModel.headerTitle(forSection: indexPath.section))
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
  
}

extension KNTransactionListViewController: SkeletonCollectionViewDelegate, SkeletonCollectionViewDataSource {
  
  func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 3
  }
  
  func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
    String(describing: KNHistoryTransactionCollectionViewCell.self)
  }
  
  func collectionSkeletonView(_ skeletonView: UICollectionView, skeletonCellForItemAt indexPath: IndexPath) -> UICollectionViewCell? {
    let cell = collectionView.dequeueReusableCell(KNHistoryTransactionCollectionViewCell.self, indexPath: indexPath)!
    return cell
  }
  
  func collectionSkeletonView(_ skeletonView: UICollectionView, supplementaryViewIdentifierOfKind: String, at indexPath: IndexPath) -> ReusableCellIdentifier? {
    return String(describing: KNTransactionCollectionReusableView.self)
  }

}
