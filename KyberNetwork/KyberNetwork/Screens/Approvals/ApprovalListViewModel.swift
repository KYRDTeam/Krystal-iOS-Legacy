//
//  ApprovalListViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation
import Services
import AppState
import BigInt
import TransactionModule
import Dependencies

class ApprovalListViewModel {
    
    struct Actions {
        var onTapBack: () -> Void
        var onTapHistory: () -> Void
        var onTapRevoke: (Approval) -> Void
        var onOpenStatus: (String, ChainType) -> Void
        var onTapTokenSymbol: (Approval) -> Void
        var onTapSpenderAddress: (Approval) -> Void
    }
    
    var address: String {
        return AppState.shared.currentAddress.addressString
    }
    
    var searchText: String = "" {
        didSet {
            filteredApprovals = self.getFilteredApprovals(searchText: searchText)
                .map { approval in ApprovedTokenItemViewModel(approval: approval, showChainIcon: selectedChain == .all) }
            onFilterApprovalsUpdated?()
        }
    }
    
    var emptyMessage: String {
        if !searchText.isEmpty {
            return Strings.aprovalsNoRecords
        }
        if selectedChain == .all {
            return Strings.approvalNoTokenFoundOnWallet
        } else {
            return Strings.approvalNoTokenFoundOnNetwork
        }
    }
    
    var actions: Actions
    
    var totalAllowance: Double = 0 {
        didSet {
            let bigIntAmount = BigInt(totalAllowance * pow(10, 18))
            totalAllowanceString = String(format: Strings.totalAllowanceFormat,
                                          NumberFormatUtils.usdAmount(value: bigIntAmount, decimals: 18))
        }
    }
    
    var approvals: [Approval] = []
    var filteredApprovals: [ApprovedTokenItemViewModel] = []
    let service = ApprovalService()
    var onFetchApprovals: (() -> Void)?
    var onFilterApprovalsUpdated: (() -> Void)?
    var onUpdatePendingTx: ((Bool) -> Void)?
    var selectedChain: ChainType = AppState.shared.isSelectedAllChain ? .all : AppState.shared.currentChain
    var totalAllowanceString: String?
    
    @UserDefault(key: "user_has_interact_approval", defaultValue: false)
    var userHasInteractApproval: Bool
    
    var isRevokeAllowed: Bool {
        return !AppState.shared.currentAddress.isWatchWallet
    }
    
    init(actions: Actions) {
        self.actions = actions
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidChangeAddress, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(kTransactionDidUpdateNotificationKey), object: nil)
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidSwitchAddress),
            name: AppEventCenter.shared.kAppDidChangeAddress,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.transactionStateDidUpdate),
            name: Notification.Name(kTransactionDidUpdateNotificationKey),
            object: nil
        )
    }
    
    @objc func appDidSwitchAddress() {
        checkPendingTx()
    }
    
    @objc func transactionStateDidUpdate() {
        checkPendingTx()
    }
    
    func checkPendingTx() {
        let pendingTransaction = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().first { transaction in
            transaction.state == .pending
        }
        onUpdatePendingTx?(pendingTransaction != nil)
    }
    
    func fetchApprovals() {
        let chains: [Int] = selectedChain == .all ? ChainType.getAllChain().map { $0.customRPC().chainID } : [selectedChain.getChainId()]
        service.getListApproval(address: address, chainIds: chains) { [weak self, selectedChain] response in
            self?.approvals = response?.data?.approvals?.filter { approval in
                return BigInt(approval.amount ?? "0") ?? .zero >= BigInt(10).power(approval.decimals) / BigInt(10).power(6) // Should > 0.000001
            } ?? []
            self?.filteredApprovals = self?.getFilteredApprovals(searchText: self?.searchText ?? "")
                .map { approval in ApprovedTokenItemViewModel(approval: approval, showChainIcon: selectedChain == .all) } ?? []
            self?.totalAllowance = (response?.data?.atRisk?["usd"] as? Double) ?? 0
            self?.onFetchApprovals?()
        }
    }
    
    func getFilteredApprovals(searchText: String) -> [Approval] {
        let trimmedSearchText = searchText.lowercased().trimmed
        if trimmedSearchText.isEmpty {
            return approvals
        } else {
            return approvals.filter { approval in
                return approval.symbol?.lowercased().contains(trimmedSearchText) ?? false
                || approval.name?.lowercased().contains(trimmedSearchText) ?? false
                || approval.tokenAddress?.lowercased().contains(trimmedSearchText) ?? false
                || approval.spenderAddress?.lowercased().contains(trimmedSearchText) ?? false
            }
        }
    }
    
    func onTapBack() {
        actions.onTapBack()
    }
    
    func onTapHistory() {
        actions.onTapHistory()
    }
    
    func onTapRevoke(index: Int) {
        if let approval = filteredApprovals[safe: index]?.approval {
            actions.onTapRevoke(approval)
        }
    }
    
    func requestRevoke(approval: Approval, setting: TxSettingObject, onCompleted: @escaping (Error?) -> Void) {
        guard let chain = ChainType.make(chainID: approval.chainId) else {
            return
        }
        guard let spender = approval.spenderAddress else {
            return
        }
        guard let tokenAddress = approval.tokenAddress else {
            return
        }
        let service = EthereumNodeService(chain: chain)
        let gasPrice = self.getGasPrice(chain: chain, setting: setting)
        service.getSendApproveERC20TokenEncodeData(spender: spender, value: .zero) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let hex):
                service.getTransactionCount(address: self.address) { result in
                    switch result {
                    case .success(let count):
                        let signResult = KNGeneralProvider.shared.signTransactionData(chain: chain, address: AppState.shared.currentAddress, tokenAddress: tokenAddress, nonce: count, data: hex, gasPrice: gasPrice, gasLimit: setting.gasLimit)
                        switch signResult {
                        case .success(let signature):
                            KNGeneralProvider.shared.sendSignedTransactionData(signature.0, chain: chain) { result in
                                switch result {
                                case .success(let hash):
                                    self.savePendingTx(txCount: count, txHash: hash, approval: approval, transaction: signature.1)
                                    self.actions.onOpenStatus(hash, chain)
                                    onCompleted(nil)
                                case .failure(let error):
                                    onCompleted(error)
                                }
                            }
                        case .failure(let error):
                            onCompleted(error)
                        }
                    case .failure(let error):
                        onCompleted(error)
                    }
                }
            case .failure(let error):
                onCompleted(error)
            }
        }
    }
    
    func savePendingTx(txCount: Int, txHash: String, approval: Approval, transaction: SignTransaction) {
        let historyTransaction = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: approval.symbol ?? "", transactionDetailDescription: approval.tokenAddress ?? "", transactionObj: transaction.toSignTransactionObject(), eip1559Tx: nil)
        historyTransaction.hash = txHash
        historyTransaction.time = Date()
        historyTransaction.nonce = txCount
        EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
    }
    
    func getGasPrice(chain: ChainType, setting: TxSettingObject) -> BigInt {
        if let basic = setting.basic {
            switch basic.gasType {
            case .slow:
                return AppDependencies.gasConfig.getLowGasPrice(chain: chain)
            case .regular:
                return AppDependencies.gasConfig.getStandardGasPrice(chain: chain)
            case .fast:
                return AppDependencies.gasConfig.getFastGasPrice(chain: chain)
            case .superFast:
                return AppDependencies.gasConfig.getSuperFastGasPrice(chain: chain)
            }
        } else {
            return setting.advanced?.maxFee ?? .zero
        }
    }
    
    func onTapTokenSymbol(approval: Approval) {
        actions.onTapTokenSymbol(approval)
    }
    
    func onTapSpenderAddress(approval: Approval) {
        actions.onTapSpenderAddress(approval)
    }
    
}
