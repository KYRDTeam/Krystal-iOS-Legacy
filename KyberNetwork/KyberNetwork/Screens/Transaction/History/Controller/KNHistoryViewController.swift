// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import BaseModule
import AppState

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
  case swap
  case reloadAllData
}

protocol KNHistoryViewControllerDelegate: class {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent)
}

class KNHistoryViewModel {
  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()

  fileprivate(set) var tokens: [Token]

  fileprivate(set) var completedTxData: [String: [HistoryTransaction]] = [:]
  fileprivate(set) var completedTxHeaders: [String] = []
  
  fileprivate(set) var completedKrystalTxData: [String: [KrystalHistoryTransaction]] = [:]
  fileprivate(set) var completedKrystalTxHeaders: [String] = []
  
  fileprivate(set) var displayingCompletedKrystalTxData: [String: [CompletedKrystalHistoryTransactionViewModel]] = [:]
  fileprivate(set) var displayingCompletedKrystalTxHeaders: [String] = []
  
  fileprivate(set) var displayingUnsupportedChainCompletedTxHeaders: [String] = []
  fileprivate(set) var displayingUnsupportedChainCompletedTxData: [String: [PendingInternalHistoryTransactonViewModel]] = [:]

  fileprivate(set) var displayingCompletedTxData: [String: [CompletedHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingCompletedTxHeaders: [String] = []

  fileprivate(set) var pendingTxData: [String: [InternalHistoryTransaction]] = [:]
  fileprivate(set) var pendingTxHeaders: [String] = []
  
  fileprivate(set) var handledTxData: [String: [InternalHistoryTransaction]] = [:]
  fileprivate(set) var handledTxHeaders: [String] = []

  fileprivate(set) var displayingPendingTxData: [String: [PendingInternalHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingPendingTxHeaders: [String] = []

//  fileprivate(set) var currentWallet: KNWalletObject

  fileprivate(set) var isShowingPending: Bool = true

  fileprivate(set) var filters: KNTransactionFilter!
  
  var currentAddressString: String {
    return AppDelegate.session.address.addressString
  }

  init(
    tokens: [Token] = EtherscanTransactionStorage.shared.getEtherscanToken()
    ) {
    self.tokens = tokens
    self.isShowingPending = hasPendingTransactions
    self.filters = KNTransactionFilter(
      from: nil,
      to: nil,
      isSend: true,
      isReceive: true,
      isSwap: true,
      isApprove: true,
      isWithdraw: true,
      isTrade: true,
      isContractInteraction: true,
      isClaimReward: true,
      isBridge: true,
      isMultisend: true,
      tokens: self.tokensSymbol
    )
    self.updateDisplayingData()
  }
  
  var hasPendingTransactions: Bool {
      return EtherscanTransactionStorage.shared.getInternalHistoryTransaction(chain: AppState.shared.currentChain).isNotEmpty
  }

  func updateIsShowingPending(_ isShowingPending: Bool) {
    self.isShowingPending = isShowingPending
  }

  func update(tokens: [Token]) {
    self.tokens = tokens
    self.filters = KNTransactionFilter(
      from: nil,
      to: nil,
      isSend: true,
      isReceive: true,
      isSwap: true,
      isApprove: true,
      isWithdraw: true,
      isTrade: true,
      isContractInteraction: true,
      isClaimReward: true,
      isBridge: true,
      isMultisend: true,
      tokens: self.tokensSymbol
    )
    self.updateDisplayingData()
  }

  func update(completedKrystalTxData: [String: [KrystalHistoryTransaction]], completedKrystalTxHeaders: [String]) {
    self.completedKrystalTxData = completedKrystalTxData
    self.completedKrystalTxHeaders = completedKrystalTxHeaders
    self.updateDisplayingData(isPending: false)
  }

   func update(pendingTxData: [String: [InternalHistoryTransaction]], pendingTxHeaders: [String]) {
    self.pendingTxData = pendingTxData
    self.pendingTxHeaders = pendingTxHeaders
    self.updateDisplayingData(isCompleted: false)
  }

   func update(handledTxData: [String: [InternalHistoryTransaction]], handledTxHeaders: [String]) {
    self.handledTxData = handledTxData
    self.handledTxHeaders = handledTxHeaders
    self.updateDisplayingData(isCompleted: false)
  }

   func update(completedTxData: [String: [HistoryTransaction]], completedTxHeaders: [String]) {
    self.completedTxData = completedTxData
    self.completedTxHeaders = completedTxHeaders
    self.updateDisplayingData(isPending: false)
  }

//   func updateCurrentWallet(_ currentWallet: KNWalletObject) {
//    self.currentWallet = currentWallet
//  }

  var isEmptyStateHidden: Bool {
    if self.isShowingPending {
      return !self.displayingPendingTxHeaders.isEmpty
    } else if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return !self.displayingUnsupportedChainCompletedTxHeaders.isEmpty
    }
    return !self.displayingCompletedKrystalTxHeaders.isEmpty
  }

  var emptyStateIconName: String {
    return self.isShowingPending ? "no_pending_tx_icon" : "no_mined_tx_icon"
  }

  var emptyStateDescLabelString: String {
    let noPendingTx = NSLocalizedString("you.do.not.have.any.pending.transactions", value: "You do not have any pending transactions.", comment: "")
    let noCompletedTx = NSLocalizedString("you.do.not.have.any.completed.transactions", value: "You do not have any completed transactions.", comment: "")
    let noMatchingFound = NSLocalizedString("no.matching.data", value: "No matching data", comment: "")
    if self.isShowingPending {
      return self.pendingTxHeaders.isEmpty ? noPendingTx : noMatchingFound
    }
    return self.completedTxHeaders.isEmpty ? noCompletedTx : noMatchingFound
  }

  var isRateMightChangeHidden: Bool {
    return true
  }

  var transactionCollectionViewBottomPaddingConstraint: CGFloat {
    return self.isRateMightChangeHidden ? 0.0 : 192.0
  }

  var isTransactionCollectionViewHidden: Bool {
    return !self.isEmptyStateHidden
  }
  
  var tokensSymbol: [String] {
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols()
    }
    return self.tokens.map({ return $0.symbol })
  }

  var numberSections: Int {
    if self.isShowingPending { return self.displayingPendingTxHeaders.count }
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return self.displayingUnsupportedChainCompletedTxHeaders.count
    }
    return self.displayingCompletedKrystalTxHeaders.count
  }

  func header(for section: Int) -> String {
    let header: String = {
      if self.isShowingPending {
        return self.displayingPendingTxHeaders[section]
      } else if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        return self.displayingUnsupportedChainCompletedTxHeaders[section]
      }
      return self.displayingCompletedKrystalTxHeaders[section]
    }()
    return header
  }

  func numberRows(for section: Int) -> Int {
    let header = self.header(for: section)
    if self.isShowingPending {
      return self.displayingPendingTxData[header]?.count ?? 0
    } else {
      if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        return self.displayingUnsupportedChainCompletedTxData[header]?.count ?? 0
      }
      return self.displayingCompletedKrystalTxData[header]?.count ?? 0
    }
  }

  func completedTransaction(for row: Int, at section: Int) -> TransactionHistoryItemViewModelProtocol? {
    let header = self.header(for: section)
    if let trans = self.displayingCompletedKrystalTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  func pendingTransaction(for row: Int, at section: Int) -> PendingInternalHistoryTransactonViewModel? {
    let header = self.header(for: section)
    if let trans = self.displayingPendingTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  func completeTransactionForUnsupportedChain(for row: Int, at section: Int) -> PendingInternalHistoryTransactonViewModel? {
    let header = self.header(for: section)
    if let trans = self.displayingUnsupportedChainCompletedTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

   func updateDisplayingKrystalData() {
    let fromDate = self.filters.from ?? Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    let toDate = self.filters.to ?? Date().addingTimeInterval(24.0 * 60.0 * 60.0)
    let displayHeaders: [String] = {
      let data = self.completedKrystalTxHeaders.filter({
        let date = self.dateFormatter.date(from: $0) ?? Date()
        return date >= fromDate.startDate() && date < toDate.endDate()
      })
      return data
    }()
    self.displayingCompletedKrystalTxData = [:]
    displayHeaders.forEach { (header) in
      let items = self.completedKrystalTxData[header]?.filter({ return self.isCompletedKrystalTransactionIncluded($0) }).enumerated().map { (item) -> CompletedKrystalHistoryTransactionViewModel in
        return CompletedKrystalHistoryTransactionViewModel(item: item.1)
      } ?? []
      self.displayingCompletedKrystalTxData[header] = items
    }
    let filtered = displayHeaders.filter { (header) -> Bool in
      return !(self.displayingCompletedKrystalTxData[header]?.isEmpty ?? false)
    }
    self.displayingCompletedKrystalTxHeaders = filtered
  }

   func updateDisplayingData(isPending: Bool = true, isCompleted: Bool = true) {
    let fromDate = self.filters.from ?? Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    let toDate = self.filters.to ?? Date().addingTimeInterval(24.0 * 60.0 * 60.0)

    if isPending {
      self.displayingPendingTxHeaders = {
        let data = self.pendingTxHeaders.filter({
          let date = self.dateFormatter.date(from: $0) ?? Date()
          return date >= fromDate.startDate() && date < toDate.endDate()
        })
        return data
      }()
      self.displayingPendingTxData = [:]

      self.displayingPendingTxHeaders.forEach { (header) in
        let filteredPendingTxData = self.pendingTxData[header]?.sorted(by: { $0.time > $1.time })
        let items = filteredPendingTxData?.map({ (item) -> PendingInternalHistoryTransactonViewModel in
          return PendingInternalHistoryTransactonViewModel(transaction: item)
        })
        self.displayingPendingTxData[header] = items
      }
    }

    if isCompleted {
      if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
        let displayHeaders: [String] = {
          let data = self.handledTxHeaders.filter({
            let date = self.dateFormatter.date(from: $0) ?? Date()
            return date >= fromDate.startDate() && date < toDate.endDate()
          }).sorted { date1String, date2String in
            let date1 = self.dateFormatter.date(from: date1String) ?? Date()
            let date2 = self.dateFormatter.date(from: date2String) ?? Date()
            return date1 > date2
          }
          return data
        }()
        self.displayingUnsupportedChainCompletedTxData = [:]
        displayHeaders.forEach { (header) in
          let filteredHandledTxData = self.handledTxData[header]?.sorted(by: { $0.time > $1.time })
          let items = filteredHandledTxData?.filter({ return self.isInternalHistoryTransactionIncluded($0) }).map({ (item) -> PendingInternalHistoryTransactonViewModel in
            return PendingInternalHistoryTransactonViewModel(transaction: item)
          })
          self.displayingUnsupportedChainCompletedTxData[header] = items
        }
        let filtered = displayHeaders.filter { (header) -> Bool in
          return !(self.displayingUnsupportedChainCompletedTxData[header]?.isEmpty ?? false)
        }
        self.displayingUnsupportedChainCompletedTxHeaders = filtered
      } else {
        self.updateDisplayingKrystalData()
      }
    }
  }
  
  fileprivate func isInternalHistoryTransactionIncluded(_ tx: InternalHistoryTransaction) -> Bool {
    let matchedTransfer = (tx.type == .transferETH || tx.type == .transferNFT || tx.type == .transferToken) && self.filters.isSend
    let matchedReceive = (tx.type == .receiveETH || tx.type == .receiveNFT || tx.type == .receiveToken) && self.filters.isReceive
    let matchedSwap = (tx.type == .swap) && self.filters.isSwap
    let matchedAppprove = (tx.type == .allowance) && self.filters.isApprove
    let matchedSupply = (tx.type == .earn) && self.filters.isTrade
    let matchedWithdraw = (tx.type == .withdraw) && self.filters.isWithdraw
    let matchedClaimReward = (tx.type == .claimReward) && self.filters.isClaimReward
    
    let matchedContractInteraction = (tx.type == .contractInteraction) && self.filters.isContractInteraction
    let matchMultisend = tx.type == .multiSend && self.filters.isMultisend
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward || matchMultisend

    var tokenMatched = false
    var transactionToken: [String] = []
    if let sym = tx.fromSymbol {
      transactionToken.append(sym)
    }
    if let sym = tx.toSymbol {
      transactionToken.append(sym)
    }
    if transactionToken.isEmpty && self.filters.tokens.count == EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols().count {
      tokenMatched = true
    } else {
      transactionToken.forEach { transaction in
        if self.filters.tokens.contains(transaction) {
          tokenMatched = true
        }
      }
    }
    return matchedType && tokenMatched
  }

  fileprivate func isCompletedKrystalTransactionIncluded(_ tx: KrystalHistoryTransaction) -> Bool {
    let matchedTransfer = (tx.type == "Transfer") && self.filters.isSend
    let matchedReceive = (tx.type == "Received") && self.filters.isReceive
    let matchedSwap = (tx.type == "Swap") && self.filters.isSwap
    let matchedAppprove = (tx.type == "Approval") && self.filters.isApprove
    let matchedSupply = (tx.type == "Supply") && self.filters.isTrade
    let matchedWithdraw = (tx.type == "Withdraw") && self.filters.isWithdraw
    let matchedClaimReward = (tx.type == "ClaimReward") && self.filters.isClaimReward
    let matchedContractInteraction = (tx.type == "" || tx.type == "ContractInteration") && self.filters.isContractInteraction
    let matchedBridge = (tx.type == "Bridge") && filters.isBridge
    let matchedMultisend = (tx.type == "Multi-send" || tx.type == "Multi-receive") && filters.isMultisend
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward || matchedBridge || matchedMultisend

    var tokenMatched = false
    var transactionToken: [String] = []
    if let sym = tx.extraData?.token?.symbol {
      transactionToken.append(sym)
    }
    if let sym = tx.extraData?.sendToken?.symbol {
      transactionToken.append(sym)
    }
    if let sym = tx.extraData?.receiveToken?.symbol {
      transactionToken.append(sym)
    }
    if transactionToken.isEmpty && self.filters.tokens.count == EtherscanTransactionStorage.shared.getEtherscanToken().count {
      tokenMatched = true
    } else {
      transactionToken.forEach { transaction in
        if self.filters.tokens.contains(transaction) {
          tokenMatched = true
        }
      }
    }
    return matchedType && tokenMatched
  }

  var normalAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.white,
  ]

  var selectedAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.Kyber.enygold,
  ]

   func updateFilters(_ filters: KNTransactionFilter) {
    self.filters = filters
    self.updateDisplayingData()
    KNAppTracker.saveHistoryFilterData(filters)
  }

  var isShowingQuickTutorial: Bool = false

  var timeForLongPendingTx: Double {
    return KNEnvironment.default == .ropsten ? 30.0 : 300
  }

  var isShowQuickTutorialForLongPendingTx: Bool {
    return UserDefaults.standard.bool(forKey: Constants.kisShowQuickTutorialForLongPendingTx)
  }
}

class KNHistoryViewController: BaseWalletOrientedViewController {

  weak var delegate: KNHistoryViewControllerDelegate?
  fileprivate var viewModel: KNHistoryViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var transactionsTextLabel: UILabel!

  @IBOutlet weak var emptyStateContainerView: UIView!

  @IBOutlet weak var transactionCollectionView: UICollectionView!
  @IBOutlet weak var transactionCollectionViewBottomConstraint: NSLayoutConstraint!
  fileprivate var quickTutorialTimer: Timer?
  var animatingCell: UICollectionViewCell?
//  @IBOutlet weak var segmentedControl: BetterSegmentedControl!
  @IBOutlet weak var filterButton: UIButton!
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
    MixPanelManager.track("history_open", properties: ["screenid": "history"])
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.quickTutorialTimer?.invalidate()
    self.quickTutorialTimer = nil
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }
  
  override func onAppSwitchAddress() {
    EtherscanTransactionStorage.shared.updateCurrentHistoryCache()
    reloadWallet()
    self.delegate?.historyViewController(self, run: .reloadAllData)
  }
  
  override func onAppSwitchChain() {
    EtherscanTransactionStorage.shared.updateCurrentHistoryCache()
    reloadWallet()
    self.delegate?.historyViewController(self, run: .reloadAllData)
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupCollectionView()
    self.filterButton.rounded(radius: 10)
    self.swapNowButton.rounded(color: UIColor(named: "buttonBackgroundColor")!, width: 1, radius: self.swapNowButton.frame.size.height / 2)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.selectedSegmentIndex = self.viewModel.isShowingPending ? 1 : 0
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

  fileprivate func checkHavePendingTxOver5Min() -> Bool {
    var flag = false
    self.viewModel.pendingTxData.keys.forEach { (key) in
      self.viewModel.pendingTxData[key]?.forEach({ (tx) in
        if abs(tx.time.timeIntervalSinceNow) >= self.viewModel.timeForLongPendingTx {
          flag = true
        }
      })
    }

    return flag
  }

  fileprivate func setupNavigationBar() {
    self.transactionsTextLabel.text = Strings.transactions
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
    MixPanelManager.track("history_filter_open", properties: ["screenid": "history_filter"])
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
  func coordinatorUpdatePendingTransaction(
    pendingData: [String: [InternalHistoryTransaction]],
    handledData: [String: [InternalHistoryTransaction]],
    pendingDates: [String],
    handledDates: [String]
  ) {
    self.viewModel.update(pendingTxData: pendingData, pendingTxHeaders: pendingDates)
    self.viewModel.update(handledTxData: handledData, handledTxHeaders: handledDates)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdateTokens() {
    //TODO: handle update new token from etherscan
  }

  func coordinatorDidUpdateCompletedTransaction(sections: [String], data: [String: [HistoryTransaction]]) {
    self.viewModel.update(completedTxData: data, completedTxHeaders: sections)
    self.updateUIWhenDataDidChange()
  }
  
  func coordinatorDidUpdateCompletedKrystalTransaction(sections: [String], data: [String: [KrystalHistoryTransaction]]) {
    self.refreshControl.endRefreshing()
    self.viewModel.update(completedKrystalTxData: data, completedKrystalTxHeaders: sections)
    self.viewModel.update(completedTxData: [:], completedTxHeaders: [])
    self.updateUIWhenDataDidChange()
  }
  
  func coordinatorAppSwitchAddress() {
    self.viewModel.update(tokens: EtherscanTransactionStorage.shared.getEtherscanToken())
  }
  
  func coordinatorDidUpdateTransaction() {
    self.viewModel.update(tokens: EtherscanTransactionStorage.shared.getEtherscanToken())
    self.updateUIWhenDataDidChange()
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
    MixPanelManager.track("history_txn_details_open", properties: ["screenid": "history_txn_details"])
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
      cell.updateCell(with: model, index: indexPath.item)
    } else if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      guard let model = self.viewModel.completeTransactionForUnsupportedChain(for: indexPath.row, at: indexPath.section) else { return cell }
      cell.updateCell(with: model, index: indexPath.item)
    } else {
      guard let model = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      cell.updateCell(with: model, index: indexPath.item)
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
    guard KNGeneralProvider.shared.currentChain != .klaytn else {
      return nil
    }
    guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section), transaction.canSpeedUpOrCancel else { return nil }
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
