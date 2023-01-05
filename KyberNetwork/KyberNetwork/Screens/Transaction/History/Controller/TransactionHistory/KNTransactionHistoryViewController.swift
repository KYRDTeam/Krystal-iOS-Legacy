// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import Swinject
import KrystalWallets
import BaseModule
import AppState

class KNTransactionHistoryViewController: BaseWalletOrientedViewController {

  weak var delegate: KNHistoryViewControllerDelegate?
  var viewModel: KNTransactionHistoryViewModel!

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var transactionsTextLabel: UILabel!
  @IBOutlet weak var pageContainer: UIView!
  @IBOutlet weak var filterButton: UIButton!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  
  let pageViewController: UIPageViewController = {
    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    return pageVC
  }()
  
  var childListViewControllers: [BaseTransactionListViewController] = []

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.initChildViewControllers()
    self.setupPageViewController()
    self.setupUI()
    segmentedControl.highlightSelectedSegment()
  }
  
  func initChildViewControllers() {
    switch viewModel.type {
    case .krystal:
      childListViewControllers = []
    case .internal:
      childListViewControllers = []
    case .solana:
      let completedVC = KNTransactionListViewController.instantiateFromNib()
      completedVC.viewModel = DIContainer.resolve(SolanaTransactionListViewModel.self, argument: viewModel.address)
      completedVC.delegate = self
      
      let pendingVC = PendingTransactionListViewController.instantiateFromNib()
      pendingVC.viewModel = DIContainer.resolve(BasePendingTransactionListViewModel.self, argument: viewModel.address)
      pendingVC.delegate = self
      
      childListViewControllers = [completedVC, pendingVC]
    }
    
  }
  
  func setupPageViewController() {
    let defaultPageIndex = viewModel.hasPendingTransactions ? 1 : 0
    pageViewController.view.frame = self.pageContainer.bounds
    pageViewController.setViewControllers([childListViewControllers[defaultPageIndex]], direction: .forward, animated: true)
    pageViewController.dataSource = self
    pageContainer.addSubview(pageViewController.view)
    addChild(pageViewController)
    pageViewController.didMove(toParent: self)
    removeSwipeGesture()
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.filterButton.rounded(radius: 10)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.selectedSegmentIndex = viewModel.hasPendingTransactions ? 1 : 0
  }

  fileprivate func setupNavigationBar() {
    self.transactionsTextLabel.text = NSLocalizedString("transactions", value: "Transactions", comment: "")
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    viewModel.didTapBack()
  }

  @IBAction func filterButtonPressed(_ sender: Any) {
    viewModel.didTapFilter()
    MixPanelManager.track("history_filter", properties: ["screenid": "history"])
  }

  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    let direction: UIPageViewController.NavigationDirection = sender.selectedSegmentIndex == 0 ? .reverse : .forward
    pageViewController.setViewControllers([childListViewControllers[sender.selectedSegmentIndex]], direction: direction, animated: true)
  }
  
//  @IBAction func walletSelectButtonTapped(_ sender: UIButton) {
//    viewModel.didTapSelectWallet()
//  }
  
    override func onAppSwitchAddress(switchChain: Bool) {
        super.onAppSwitchAddress(switchChain: switchChain)
        
        self.childListViewControllers.forEach { $0.updateAddress(address: AppState.shared.currentAddress) }
    }

}

extension KNTransactionHistoryViewController {
  
  func coordinatorDidUpdateCompletedKrystalTransaction() {
    self.reloadData()
  }
  
  func reloadData() {
    childListViewControllers.forEach { vc in vc.reload() }
  }
}

extension KNTransactionHistoryViewController: KNTransactionFilterViewControllerDelegate {
  func transactionFilterViewController(_ controller: KNTransactionFilterViewController, apply filter: KNTransactionFilter) {
    
  }
}

extension KNTransactionHistoryViewController: UIPageViewControllerDataSource {
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    if let vc = viewController as? KNTransactionListViewController, let index = childListViewControllers.index(of: vc) {
      if index + 1 < childListViewControllers.count {
        return childListViewControllers[index + 1]
      }
    }
    return nil
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    if let vc = viewController as? KNTransactionListViewController, let index = childListViewControllers.index(of: vc) {
      if index - 1 >= 0 {
        return childListViewControllers[index - 1]
      }
    }
    return nil
  }
  
  func removeSwipeGesture() {
    for view in self.pageViewController.view.subviews {
      if let subView = view as? UIScrollView {
        subView.isScrollEnabled = false
      }
    }
  }
  
}

extension KNTransactionHistoryViewController: KNTransactionListViewControllerDelegate {
  
  func selectSwapNow(_ viewController: KNTransactionListViewController) {
    viewModel.didTapSwap()
    MixPanelManager.track("history_txn_swap", properties: ["screenid": "history_txn_details"])
  }
  
  func transactionListViewController(_ viewController: KNTransactionListViewController, openDetail transaction: TransactionHistoryItem) {
    viewModel.didSelectTransaction(transaction: transaction)
    MixPanelManager.track("history_txn_detail", properties: ["screenid": "history_txn_details"])
  }

}

extension KNTransactionHistoryViewController: PendingTransactionListViewControllerDelegate {
  
  func selectSwapNow(_ viewController: PendingTransactionListViewController) {
    viewModel.didTapSwap()
  }
  
  func pendingTransactionListViewController(_ viewController: PendingTransactionListViewController, speedupTransaction transaction: InternalHistoryTransaction) {
    viewModel.didSelectSpeedupTransaction(transaction: transaction)
  }
  
  func pendingTransactionListViewController(_ viewController: PendingTransactionListViewController, cancelTransaction transaction: InternalHistoryTransaction) {
    viewModel.didSelectCancelTransaction(transaction: transaction)
  }
  
  func pendingTransactionListViewController(_ viewController: PendingTransactionListViewController, openDetail transaction: InternalHistoryTransaction) {
    viewModel.didSelectPendingTransaction(transaction: transaction)
  }
  
}
