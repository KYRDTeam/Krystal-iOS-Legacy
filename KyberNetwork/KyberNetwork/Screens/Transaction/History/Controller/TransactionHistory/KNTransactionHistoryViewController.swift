// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit

class KNTransactionHistoryViewController: KNBaseViewController {

  weak var delegate: KNHistoryViewControllerDelegate?
  var viewModel: KNTransactionHistoryViewModel!

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var transactionsTextLabel: UILabel!
  @IBOutlet weak var pageContainer: UIView!
  @IBOutlet weak var filterButton: UIButton!
  @IBOutlet weak var walletSelectButton: UIButton!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  
  let pageViewController: UIPageViewController = {
    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    return pageVC
  }()
  
  var childListViewControllers: [KNTransactionListViewController] = []

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.initChildViewControllers()
    self.setupPageViewController()
    self.setupUI()
    segmentedControl.highlightSelectedSegment()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.reloadData()
  }
  
  func initChildViewControllers() {
    switch viewModel.type {
    case .krystal:
      let completedVC = KNTransactionListViewController.instantiateFromNib()
      completedVC.viewModel = KrystalTransactionHistoryViewModel(currentWallet: viewModel.currentWallet)
      completedVC.delegate = self
      
      let pendingVC = KNTransactionListViewController.instantiateFromNib()
      pendingVC.viewModel = PendingTransactionHistoryViewModel(currentWallet: viewModel.currentWallet)
      pendingVC.delegate = self
      
      childListViewControllers = [completedVC, pendingVC]
    case .external:
      childListViewControllers = []
    case .solana:
      childListViewControllers = []
    }
    
  }
  
  func setupPageViewController() {
    pageViewController.view.frame = self.pageContainer.bounds
    pageViewController.setViewControllers([childListViewControllers[0]], direction: .forward, animated: true)
    pageViewController.dataSource = self
    pageContainer.addSubview(pageViewController.view)
    addChild(pageViewController)
    pageViewController.didMove(toParent: self)
    removeSwipeGesture()
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.filterButton.rounded(radius: 10)
    self.walletSelectButton.rounded(radius: self.walletSelectButton.frame.size.height / 2)
    self.walletSelectButton.setTitle(self.viewModel.currentWallet.address, for: .normal)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.selectedSegmentIndex = 0
  }

  override func quickTutorialNextAction() {
    self.dismissTutorialOverlayer()
//    self.animateResetReviewCellActionForTutorial()
//    self.viewModel.isShowingQuickTutorial = false
    self.reloadData()
  }

  fileprivate func setupNavigationBar() {
    self.transactionsTextLabel.text = NSLocalizedString("transactions", value: "Transactions", comment: "")
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    viewModel.didTapBack()
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
//      self.delegate?.historyViewController(self, run: .dismiss)
    }
  }

  @IBAction func filterButtonPressed(_ sender: Any) {
    viewModel.didTapFilter()
  }

  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    let direction: UIPageViewController.NavigationDirection = sender.selectedSegmentIndex == 0 ? .reverse : .forward
    pageViewController.setViewControllers([childListViewControllers[sender.selectedSegmentIndex]], direction: direction, animated: true)
  }
  
  @IBAction func walletSelectButtonTapped(_ sender: UIButton) {
//    self.delegate?.historyViewController(self, run: KNHistoryViewEvent.openWalletsListPopup)
  }
}

extension KNTransactionHistoryViewController {
  func coordinatorUpdatePendingTransaction(currentWallet: KNWalletObject) {
//    self.viewModel.reloadPendingTransactions()
//    self.viewModel.reloadCompletedTransactions()
    self.viewModel.updateCurrentWallet(currentWallet)
    self.childListViewControllers.forEach { $0.updateWallet(wallet: currentWallet) }
  }

  func coordinatorUpdateWalletObjects() {
    guard let currentWallet = KNWalletStorage.shared.get(forPrimaryKey: self.viewModel.currentWallet.address) else { return }
    self.viewModel.updateCurrentWallet(currentWallet)
    self.childListViewControllers.forEach { $0.updateWallet(wallet: currentWallet) }
  }

  func coordinatorUpdateTokens() {
    //TODO: handle update new token from etherscan
  }
  
  func coordinatorDidUpdateCompletedKrystalTransaction() {
    self.reloadData()
  }

  func coordinatorUpdateNewSession(wallet: KNWalletObject) {
    self.viewModel.updateCurrentWallet(wallet)
    self.childListViewControllers.forEach { $0.updateWallet(wallet: wallet) }
    self.walletSelectButton.setTitle(wallet.address, for: .normal)
  }
  
  func reloadData() {
    childListViewControllers.forEach { vc in vc.reload() }
  }
}

extension KNTransactionHistoryViewController: KNTransactionFilterViewControllerDelegate {
  func transactionFilterViewController(_ controller: KNTransactionFilterViewController, apply filter: KNTransactionFilter) {
    childListViewControllers.forEach { $0.applyFilter(filter: filter) }
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
//    delegate?.historyViewController(self, run: .swap)
  }
  
  func transactionListViewController(_ viewController: KNTransactionListViewController, speedupTransaction transaction: TransactionHistoryItem) {
    // TODO: - Should create a SpeedUpableTransaction protocol instead
    guard let transaction = transaction as? InternalHistoryTransaction else { return }
//    delegate?.historyViewController(self, run: .speedUpTransaction(transaction: transaction))
  }
  
  func transactionListViewController(_ viewController: KNTransactionListViewController, cancelTransaction transaction: TransactionHistoryItem) {
    // TODO: - Should create a CancellableTransaction protocol instead
    guard let transaction = transaction as? InternalHistoryTransaction else { return }
//    delegate?.historyViewController(self, run: .cancelTransaction(transaction: transaction))
  }
  
  func refreshTransactions(_ viewController: KNTransactionListViewController) {
//    delegate?.historyViewController(self, run: .reloadAllData)
  }

}
