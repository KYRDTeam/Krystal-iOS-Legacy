//
//  KNTransactionListViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import UIKit
import SwipeCellKit

protocol KNTransactionListViewControllerDelegate: AnyObject {
  func selectSwapNow(_ viewController: KNTransactionListViewController)
  func transactionListViewController(_ viewController: KNTransactionListViewController, speedupTransaction transaction: TransactionHistoryItem)
  func transactionListViewController(_ viewController: KNTransactionListViewController, cancelTransaction transaction: TransactionHistoryItem)
  func refreshTransactions(_ viewController: KNTransactionListViewController)
}

class KNTransactionListViewController: UIViewController {
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var emptyView: UIView!
  
  var viewModel: KNTransactionListViewModel!
  weak var delegate: KNTransactionListViewControllerDelegate?
  var animatingCell: UICollectionViewCell?
  private let refreshControl = UIRefreshControl()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupCollectionView()
    reload()
  }
  
  func setupCollectionView() {
    self.collectionView.registerCellNib(KNHistoryTransactionCollectionViewCell.self)
    self.collectionView.registerHeaderCellNib(KNTransactionCollectionReusableView.self)
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.collectionView.refreshControl = self.refreshControl
    self.refreshControl.tintColor = .lightGray
    self.refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
  }
  
  func reloadUI() {
    collectionView?.reloadData()
    collectionView?.isHidden = viewModel.isTransactionListEmpty
    emptyView?.isHidden = !viewModel.isTransactionListEmpty
    refreshControl.endRefreshing()
  }
  
  fileprivate func animateReviewCellActionForTutorial() {
    guard let firstCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) else { return }
    let speedupLabel = UILabel(frame: CGRect(x: firstCell.frame.size.width, y: 0, width: 77, height: 60))
    let cancelLabel = UILabel(frame: CGRect(x: firstCell.frame.size.width + 77, y: 0, width: 77, height: 60))
    self.animatingCell = firstCell
    firstCell.clipsToBounds = false

    speedupLabel.text = "speed up".toBeLocalised()
    speedupLabel.textAlignment = .center
    speedupLabel.font = UIFont.Kyber.bold(with: 14)
    speedupLabel.backgroundColor = UIColor.Kyber.speedUpOrange
    speedupLabel.textColor = .white
    speedupLabel.tag = 101

    cancelLabel.text = "cancel".toBeLocalised()
    cancelLabel.textAlignment = .center
    cancelLabel.font = UIFont.Kyber.bold(with: 14)
    cancelLabel.backgroundColor = UIColor.Kyber.cancelGray
    cancelLabel.textColor = .white
    cancelLabel.tag = 102

    firstCell.contentView.addSubview(speedupLabel)
    firstCell.contentView.addSubview(cancelLabel)
    UIView.animate(withDuration: 0.3) {
      firstCell.frame = CGRect(x: firstCell.frame.origin.x - 77 * 2, y: firstCell.frame.origin.y, width: firstCell.frame.size.width, height: firstCell.frame.size.height)
    }
  }

  fileprivate func animateResetReviewCellActionForTutorial() {
    guard let firstCell = self.animatingCell else { return }
    let speedupLabel = firstCell.viewWithTag(101)
    let cancelLabel = firstCell.viewWithTag(102)
    UIView.animate(withDuration: 0.3, animations: {
      firstCell.frame = CGRect(x: 0, y: firstCell.frame.origin.y, width: firstCell.frame.size.width, height: firstCell.frame.size.height)
    }, completion: { _ in
      speedupLabel?.removeFromSuperview()
      cancelLabel?.removeFromSuperview()
      self.animatingCell = nil
    })
  }
  
  @IBAction func swapWasTapped(_ sender: Any) {
    delegate?.selectSwapNow(self)
  }
  
  @objc private func refreshData(_ sender: Any) {
    guard viewModel.canRefresh else {
      refreshControl.endRefreshing()
      return
    }
    guard self.refreshControl.isRefreshing else {
      return
    }
    delegate?.refreshTransactions(self)
  }
  
  func updateWallet(wallet: KNWalletObject) {
    DispatchQueue.global().async {
      self.viewModel.updateWallet(wallet: wallet) {
        DispatchQueue.main.async {
          self.reloadUI()
        }
      }
    }
  }
  
  func applyFilter(filter: KNTransactionFilter) {
    DispatchQueue.global().async {
      self.viewModel.applyFilter(filter: filter)
      DispatchQueue.main.async {
        self.reloadUI()
      }
    }
  }
  
  func reload() {
    DispatchQueue.global().async {
      self.viewModel.reloadData {
        DispatchQueue.main.async {
          self.reloadUI()
        }
      }
    }
  }
  
}

extension KNTransactionListViewController: SwipeCollectionViewCellDelegate {
  func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard self.viewModel.isTransactionActionEnabled else {
      return nil
    }
    guard orientation == .right else {
      return nil
    }
    guard let transaction = self.viewModel.item(forIndex: indexPath.item, inSection: indexPath.section) else { return nil }
    let speedUp = SwipeAction(style: .default, title: nil) { [weak self] (_, _) in
      guard let self = self else { return }
      self.delegate?.transactionListViewController(self, speedupTransaction: transaction)
    }
    speedUp.hidesWhenSelected = true
    speedUp.title = NSLocalizedString("speed up", value: "Speed Up", comment: "").uppercased()
    speedUp.textColor = UIColor(named: "normalTextColor")
    speedUp.font = UIFont.Kyber.medium(with: 12)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 68))!
    speedUp.backgroundColor = UIColor(patternImage: resized)
    let cancel = SwipeAction(style: .destructive, title: nil) { [weak self] _, _ in
      guard let self = self else { return }
      self.delegate?.transactionListViewController(self, cancelTransaction: transaction)
    }

    cancel.title = NSLocalizedString("cancel", value: "Cancel", comment: "").uppercased()
    cancel.textColor = UIColor(named: "normalTextColor")
    cancel.font = UIFont.Kyber.medium(with: 12)
    cancel.backgroundColor = UIColor(patternImage: resized)
    return [cancel, speedUp]
  }

  func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .destructive
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
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
    return CGSize(
      width: collectionView.frame.width,
      height: 24
    )
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if viewModel.isLoadingMore { return }
    if indexPath.section == viewModel.numberOfSections - 1 && indexPath.item == viewModel.numberOfItems(inSection: indexPath.section) - 1 {
      DispatchQueue.global().async {
        self.viewModel.loadMoreIfNeeded {
          DispatchQueue.main.async {
            self.reloadUI()
          }
        }
      }
    }
  }
}

extension KNTransactionListViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return viewModel.numberOfSections
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewModel.numberOfItems(inSection: section)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(KNHistoryTransactionCollectionViewCell.self, indexPath: indexPath)!
    cell.delegate = self
    if let item = viewModel.item(forIndex: indexPath.item, inSection: indexPath.section) {
      cell.updateCell(with: item.toViewModel())
    }
    return cell
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
