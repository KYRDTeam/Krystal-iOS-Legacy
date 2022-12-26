//
//  PendingTxViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 26/12/2022.
//

import UIKit
import SwipeCellKit
import BaseModule
import BigInt
import Dependencies

class PendingTxViewController: BaseWalletOrientedViewController {
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var transactionCollectionView: UICollectionView!
    private let refreshControl = UIRefreshControl()
    fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
    var txDetailsCoordinator: KNTransactionDetailsCoordinator?
    
    var viewModel: PendingTxViewModel!
    
    fileprivate lazy var dateFormatter: DateFormatter = {
      return DateFormatterUtil.shared.limitOrderFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.observeAppEvents()
        self.appCoordinatorPendingTransactionDidUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateUIWhenDataDidChange()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func onAppSwitchAddress() {
        EtherscanTransactionStorage.shared.updateCurrentHistoryCache()
        reloadWallet()
        reloadAllData()
    }
    
    override func onAppSwitchChain() {
        EtherscanTransactionStorage.shared.updateCurrentHistoryCache()
        reloadWallet()
        reloadAllData()
        updatePendingTxList()
    }
    
    fileprivate func setupUI() {
        self.setupCollectionView()
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
        self.emptyView.isHidden = self.viewModel.isEmptyStateHidden
        self.transactionCollectionView.isHidden = self.viewModel.isTransactionCollectionViewHidden
        
        self.transactionCollectionView.reloadData()
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    @objc private func refreshData(_ sender: Any) {
        guard !self.viewModel.isShowingPending else {
            self.refreshControl.endRefreshing()
            return
        }
        guard self.refreshControl.isRefreshing else { return }
        self.reloadAllData()
    }
    
    func reloadAllData() {
        AppDelegate.session.transactionCoordinator?.loadEtherscanTransactions(isInit: true)
    }
    
    override func onAppSwitchAddress(switchChain: Bool) {
        super.onAppSwitchAddress(switchChain: switchChain)
        
        updatePendingTxList()
    }
    
    func observeAppEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePendingTxList),
            name: Notification.Name(kTransactionDidUpdateNotificationKey),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(kTokenTransactionListDidUpdateNotificationKey), object: nil)
    }
    
    @objc func appDidSwitchAddress() {
        updatePendingTxList()
    }
    
    @objc func updatePendingTxList() {
        self.viewModel.update(tokens: EtherscanTransactionStorage.shared.getEtherscanToken())
        self.appCoordinatorPendingTransactionDidUpdate()
    }
    
    func appCoordinatorPendingTransactionDidUpdate() {
        let pendingDates: [String] = {
            let dates = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().map { return self.dateFormatter.string(from: $0.time) }
            var uniqueDates = [String]()
            dates.forEach({
                if !uniqueDates.contains($0) { uniqueDates.append($0) }
            })
            return uniqueDates
        }()
        
        let handledDates: [String] = {
            let dates = EtherscanTransactionStorage.shared.getHandledInternalHistoryTransactionForUnsupportedApi().map { return self.dateFormatter.string(from: $0.time) }
            var uniqueDates = [String]()
            dates.forEach({
                if !uniqueDates.contains($0) { uniqueDates.append($0) }
            })
            return uniqueDates
        }()
        
        let sectionData: [String: [InternalHistoryTransaction]] = {
            var data: [String: [InternalHistoryTransaction]] = [:]
            EtherscanTransactionStorage.shared.getInternalHistoryTransaction().forEach { tx in
                var trans = data[self.dateFormatter.string(from: tx.time)] ?? []
                trans.append(tx)
                data[self.dateFormatter.string(from: tx.time)] = trans
            }
            return data
        }()
        
        let sectionHandledData: [String: [InternalHistoryTransaction]] = {
            var data: [String: [InternalHistoryTransaction]] = [:]
            EtherscanTransactionStorage.shared.getHandledInternalHistoryTransactionForUnsupportedApi().forEach { tx in
                var trans = data[self.dateFormatter.string(from: tx.time)] ?? []
                trans.append(tx)
                data[self.dateFormatter.string(from: tx.time)] = trans
            }
            return data
        }()
        
        self.coordinatorUpdatePendingTransaction(
            pendingData: sectionData,
            handledData: sectionHandledData,
            pendingDates: pendingDates,
            handledDates: handledDates
        )
        
    }
    
    @IBAction func swapTapped(_ sender: Any) {
        parent?.navigationController?.popViewController(animated: true)
        AppDependencies.router.openSwap()
    }
    
}


extension PendingTxViewController {
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

extension PendingTxViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return }
        openPendingTx(transaction: transaction.internalTransaction)
        MixPanelManager.track("history_txn_details_open", properties: ["screenid": "history_txn_details"])
    }
}

extension PendingTxViewController: UICollectionViewDelegateFlowLayout {
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

extension PendingTxViewController: UICollectionViewDataSource {
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

extension PendingTxViewController: SwipeCollectionViewCellDelegate {
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
            guard KNGeneralProvider.shared.currentChain != .klaytn else {
                self.showErrorTopBannerMessage(message: "Unsupported action")
                return
            }
            self.openTransactionSpeedUpViewController(transaction: transaction.internalTransaction)
        }
        speedUp.hidesWhenSelected = true
        speedUp.title = NSLocalizedString("speed up", value: "Speed Up", comment: "").uppercased()
        speedUp.textColor = UIColor(named: "normalTextColor")
        speedUp.font = UIFont.Kyber.medium(with: 12)
        let bgImg = UIImage(named: "history_cell_edit_bg")!
        let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 68))!
        speedUp.backgroundColor = UIColor(patternImage: resized)
        let cancel = SwipeAction(style: .destructive, title: nil) { _, _ in
            guard KNGeneralProvider.shared.currentChain != .klaytn else {
                self.showErrorTopBannerMessage(message: "Unsupported action")
                return
            }
            self.openTransactionCancelConfirmPopUpFor(transaction: transaction.internalTransaction)
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

extension PendingTxViewController {
    
    func openPendingTx(transaction: InternalHistoryTransaction) {
        switch transaction.type {
        case .bridge:
            let module = TransactionDetailModule.build(internalTx: transaction)
            parent?.navigationController?.pushViewController(module, animated: true)
        default:
            guard let navigation = parent?.navigationController else { return }
            let coordinator = KNTransactionDetailsCoordinator(navigationController: navigation, transaction: transaction)
            coordinator.start()
            self.txDetailsCoordinator = coordinator
        }
    }
    
}

extension PendingTxViewController {
    
    func openTransactionCancelConfirmPopUpFor(transaction: InternalHistoryTransaction) {
        let gasLimit: BigInt = {
            if KNGeneralProvider.shared.isUseEIP1559 {
                return BigInt(transaction.eip1559Transaction?.gasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
            } else {
                return BigInt(transaction.transactionObject?.gasLimit ?? "") ?? BigInt(0)
            }
        }()
        
        let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
        viewModel.updateGasPrices(
            fast: KNGasCoordinator.shared.fastKNGas,
            medium: KNGasCoordinator.shared.standardKNGas,
            slow: KNGasCoordinator.shared.lowKNGas,
            superFast: KNGasCoordinator.shared.superFastKNGas
        )
        
        viewModel.isCancelMode = true
        viewModel.transaction = transaction
        let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
        vc.delegate = self
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
    
    fileprivate func openTransactionSpeedUpViewController(transaction: InternalHistoryTransaction) {
        let gasLimit: BigInt = {
            if KNGeneralProvider.shared.isUseEIP1559 {
                return BigInt(transaction.eip1559Transaction?.reservedGasLimit.drop0x ?? "", radix: 16) ?? BigInt(0)
            } else {
                return BigInt(transaction.transactionObject?.reservedGasLimit ?? "") ?? BigInt(0)
            }
        }()
        let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: .superFast, currentRatePercentage: 0, isUseGasToken: false)
        viewModel.updateGasPrices(
            fast: KNGasCoordinator.shared.fastKNGas,
            medium: KNGasCoordinator.shared.standardKNGas,
            slow: KNGasCoordinator.shared.lowKNGas,
            superFast: KNGasCoordinator.shared.superFastKNGas
        )
        
        viewModel.transaction = transaction
        viewModel.isSpeedupMode = true
        let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
        let controller = KNTransactionStatusPopUp(transaction: transaction)
        controller.delegate = self
        present(controller, animated: true, completion: nil)
        self.transactionStatusVC = controller
    }
    
}

extension PendingTxViewController: GasFeeSelectorPopupViewControllerDelegate {
    func gasFeeSelectorPopupViewController(_ controller: KNBaseViewController, run event: GasFeeSelectorPopupViewEvent) {
        switch event {
        case .helpPressed(let tag):
            var message = "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised()
            switch tag {
            case 1:
                message = KNGeneralProvider.shared.isUseEIP1559 ? "gas.limit.help".toBeLocalised() : "gas.limit.legacy.help".toBeLocalised()
            case 2:
                message = "max.priority.fee.help".toBeLocalised()
            case 3:
                message = KNGeneralProvider.shared.isUseEIP1559 ? "max.fee.help".toBeLocalised() : "gas.price.legacy.help".toBeLocalised()
            case 4:
                message = "nonce.help".toBeLocalised()
            default:
                break
            }
            showBottomBannerView(
                message: message,
                icon: UIImage(named: "help_icon_large") ?? UIImage(),
                time: 10
            )
        case .speedupTransactionSuccessfully(let speedupTransaction):
            self.openTransactionStatusPopUp(transaction: speedupTransaction)
        case .cancelTransactionSuccessfully(let cancelTransaction):
            self.openTransactionStatusPopUp(transaction: cancelTransaction)
        case .speedupTransactionFailure(let message):
            showTopBannerView(message: message)
        case .cancelTransactionFailure(let message):
            showTopBannerView(message: message)
        default:
            break
        }
    }
}

extension PendingTxViewController: KNTransactionStatusPopUpDelegate {
    func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
        switch action {
        case .swap:
            AppDependencies.router.openSwap()
        case .speedUp(tx: let tx):
            self.openTransactionSpeedUpViewController(transaction: tx)
        case .cancel(tx: let tx):
            self.openTransactionCancelConfirmPopUpFor(transaction: tx)
        case .openLink(url: let url):
            AppDependencies.router.openExternalURL(url: url)
        case .transfer:
            // TODO: Open transfer
            return
        case .goToSupport:
            AppDependencies.router.openExternalURL(url: "https://docs.krystal.app/")
        default:
            break
        }
        self.transactionStatusVC = nil
    }
}

