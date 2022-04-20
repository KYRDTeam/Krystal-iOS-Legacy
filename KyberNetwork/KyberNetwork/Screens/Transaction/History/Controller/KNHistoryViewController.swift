// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit

//swiftlint:disable file_length
enum KNHistoryViewEvent {
  case selectPendingTransaction(transaction: InternalHistoryTransaction)
  case selectCompletedTransaction(data: CompletedHistoryTransactonViewModel)
  case selectCompletedKrystalTransaction(data: CompletedKrystalHistoryTransactionViewModel)
  case dismiss
  case cancelTransaction(transaction: InternalHistoryTransaction)
  case speedUpTransaction(transaction: InternalHistoryTransaction)
  case quickTutorial(pointsAndRadius: [(CGPoint, CGFloat)])
  case openEtherScanWalletPage
  case openKyberWalletPage
  case openWalletsListPopup
  case swap
  case reloadAllData
}

protocol KNHistoryViewControllerDelegate: class {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent)
}

class KNHistoryViewController: KNBaseViewController {

  weak var delegate: KNHistoryViewControllerDelegate?
  fileprivate var viewModel: KNHistoryViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var transactionsTextLabel: UILabel!

  @IBOutlet weak var emptyStateContainerView: UIView!

  @IBOutlet weak var transactionCollectionView: UICollectionView!
  @IBOutlet weak var transactionCollectionViewBottomConstraint: NSLayoutConstraint!
  fileprivate var quickTutorialTimer: Timer?
  var animatingCell: UICollectionViewCell?
  @IBOutlet weak var filterButton: UIButton!
  @IBOutlet weak var walletSelectButton: UIButton!
  @IBOutlet weak var swapNowButton: UIButton!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  private let refreshControl = UIRefreshControl()
  
  init(viewModel: KNHistoryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNHistoryViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.quickTutorialTimer?.invalidate()
    self.quickTutorialTimer = nil
  }

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    segmentedControl.highlightSelectedSegment()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIWhenDataDidChange()
  }

  fileprivate func showQuickTutorial() {
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.quickTutorialTimer?.invalidate()
    self.quickTutorialTimer = nil
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupCollectionView()
    self.filterButton.rounded(radius: 10)
    self.walletSelectButton.rounded(radius: self.walletSelectButton.frame.size.height / 2)
    self.walletSelectButton.setTitle(self.viewModel.currentWallet.address, for: .normal)
    self.swapNowButton.rounded(color: UIColor(named: "buttonBackgroundColor")!, width: 1, radius: self.swapNowButton.frame.size.height / 2)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.selectedSegmentIndex = 1
  }

  override func quickTutorialNextAction() {
    self.dismissTutorialOverlayer()
    self.animateResetReviewCellActionForTutorial()
    self.viewModel.isShowingQuickTutorial = false
    self.updateUIWhenDataDidChange()
  }

  fileprivate func animateReviewCellActionForTutorial() {
    guard let firstCell = self.transactionCollectionView.cellForItem(at: IndexPath(row: 0, section: 0)) else { return }
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

  fileprivate func setupNavigationBar() {
    self.transactionsTextLabel.text = NSLocalizedString("transactions", value: "Transactions", comment: "")
    //TODO: set address text for address select button
//    self.currentAddressLabel.text = self.viewModel.currentWallet.address.lowercased()
    self.updateDisplayTxsType(self.viewModel.isShowingPending)
  }

  fileprivate func setupCollectionView() {
    let nib = UINib(nibName: KNHistoryTransactionCollectionViewCell.className, bundle: nil)
    self.transactionCollectionView.register(nib, forCellWithReuseIdentifier: KNHistoryTransactionCollectionViewCell.cellID)
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.transactionCollectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: KNTransactionCollectionReusableView.viewID)
    self.transactionCollectionView.delegate = self
    self.transactionCollectionView.dataSource = self
    self.refreshControl.tintColor = .lightGray
    self.refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    self.transactionCollectionView.refreshControl = self.refreshControl
    self.updateUIWhenDataDidChange()
  }

  fileprivate func updateUIWhenDataDidChange() {
    guard self.viewModel.isShowingQuickTutorial == false else {
      return
    }
    self.emptyStateContainerView.isHidden = self.viewModel.isEmptyStateHidden

    self.transactionCollectionView.isHidden = self.viewModel.isTransactionCollectionViewHidden
    self.transactionCollectionViewBottomConstraint.constant = self.viewModel.transactionCollectionViewBottomPaddingConstraint + self.bottomPaddingSafeArea()
    
    self.transactionCollectionView.reloadData()
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraintsIfNeeded()
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.historyViewController(self, run: .dismiss)
  }
  
  @IBAction func swapButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: .swap)
  }

  fileprivate func updateDisplayTxsType(_ isShowPending: Bool) {
    self.viewModel.updateIsShowingPending(isShowPending)
    self.updateUIWhenDataDidChange()
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.historyViewController(self, run: .dismiss)
    }
  }

  @IBAction func filterButtonPressed(_ sender: Any) {
    let viewModel = KNTransactionFilterViewModel(
      tokens: self.viewModel.tokensSymbol,
      filter: self.viewModel.filters
    )
    let filterVC = KNTransactionFilterViewController(viewModel: viewModel)
    filterVC.loadViewIfNeeded()
    filterVC.delegate = self
    self.navigationController?.pushViewController(filterVC, animated: true)
  }

  @IBAction func emptyStateEtherScanButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: KNHistoryViewEvent.openEtherScanWalletPage)
  }

  @IBAction func emptyStateKyberButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: KNHistoryViewEvent.openKyberWalletPage)
  }

  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    self.viewModel.updateIsShowingPending(sender.selectedSegmentIndex == 1)
    self.updateUIWhenDataDidChange()
  }
  
  @IBAction func walletSelectButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: KNHistoryViewEvent.openWalletsListPopup)
  }
  
  @objc private func refreshData(_ sender: Any) {
    guard !self.viewModel.isShowingPending else {
      self.refreshControl.endRefreshing()
      return
    }
    guard self.refreshControl.isRefreshing else { return }
    self.delegate?.historyViewController(self, run: .reloadAllData)
  }
}

extension KNHistoryViewController {
  func coordinatorUpdatePendingTransaction(currentWallet: KNWalletObject) {
    self.viewModel.reloadPendingTransactions()
    self.viewModel.reloadCompletedTransactions()
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdateWalletObjects() {
    guard let currentWallet = KNWalletStorage.shared.get(forPrimaryKey: self.viewModel.currentWallet.address) else { return }
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdateTokens() {
    //TODO: handle update new token from etherscan
  }
  
  func coordinatorDidUpdateCompletedKrystalTransaction() {
    self.refreshControl.endRefreshing()
    self.viewModel.reloadKrystalTransactions()
    self.transactionCollectionView.reloadData()
  }

  func coordinatorUpdateNewSession(wallet: KNWalletObject) {
    self.viewModel.updateCurrentWallet(wallet)
    self.walletSelectButton.setTitle(wallet.address, for: .normal)
    self.viewModel.update(tokens: EtherscanTransactionStorage.shared.getEtherscanToken())
  }
}

extension KNHistoryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if self.viewModel.isShowingPending {
      guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectPendingTransaction(transaction: transaction.internalTransaction))
    } else if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      guard let transaction = self.viewModel.completeTransactionForUnsupportedChain(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectPendingTransaction(transaction: transaction.internalTransaction))
    } else {
      if let transaction = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) as? CompletedKrystalHistoryTransactionViewModel {
        self.delegate?.historyViewController(self, run: .selectCompletedKrystalTransaction(data: transaction))
      }
    }
  }
}

extension KNHistoryViewController: UICollectionViewDelegateFlowLayout {
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
}

extension KNHistoryViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.viewModel.numberSections
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows(for: section)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNHistoryTransactionCollectionViewCell.cellID, for: indexPath) as! KNHistoryTransactionCollectionViewCell
    cell.delegate = self
    if self.viewModel.isShowingPending {
      guard let model = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      cell.updateCell(with: model)
    } else if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      guard let model = self.viewModel.completeTransactionForUnsupportedChain(for: indexPath.row, at: indexPath.section) else { return cell }
      cell.updateCell(with: model)
    } else {
      guard let model = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      cell.updateCell(with: model)
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionView.elementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.viewID, for: indexPath) as! KNTransactionCollectionReusableView
      headerView.updateView(with: self.viewModel.header(for: indexPath.section))
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}

extension KNHistoryViewController: KNTransactionFilterViewControllerDelegate {
  func transactionFilterViewController(_ controller: KNTransactionFilterViewController, apply filter: KNTransactionFilter) {
    self.viewModel.updateFilters(filter)
    self.updateUIWhenDataDidChange()
  }
}

extension KNHistoryViewController: SwipeCollectionViewCellDelegate {
  func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard self.viewModel.isShowingPending else {
      return nil
    }
    guard orientation == .right else {
      return nil
    }
    guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section)  else { return nil }
    let speedUp = SwipeAction(style: .default, title: nil) { (_, _) in
      self.delegate?.historyViewController(self, run: .speedUpTransaction(transaction: transaction.internalTransaction))
    }
    speedUp.hidesWhenSelected = true
    speedUp.title = NSLocalizedString("speed up", value: "Speed Up", comment: "").uppercased()
    speedUp.textColor = UIColor(named: "normalTextColor")
    speedUp.font = UIFont.Kyber.medium(with: 12)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 68))!
    speedUp.backgroundColor = UIColor(patternImage: resized)
    let cancel = SwipeAction(style: .destructive, title: nil) { _, _ in
      self.delegate?.historyViewController(self, run: .cancelTransaction(transaction: transaction.internalTransaction))
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
