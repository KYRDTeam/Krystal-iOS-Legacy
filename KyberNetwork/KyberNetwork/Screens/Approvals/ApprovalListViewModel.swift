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
    }
    
    var address: String {
        return AppState.shared.currentAddress.addressString
    }
    
    var searchText: String = "" {
        didSet {
            filteredApprovals = self.getFilteredApprovals(searchText: searchText)
                .map { approval in ApprovedTokenItemViewModel(approval: approval) }
            onFilterApprovalsUpdated?()
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
    var selectedChain: ChainType = AppState.shared.isSelectedAllChain ? .all : AppState.shared.currentChain
    var totalAllowanceString: String?
    
    @UserDefault(key: "user_has_interact_approval", defaultValue: false)
    var userHasInteractApproval: Bool
    
    init(actions: Actions) {
        self.actions = actions
    }
    
    func fetchApprovals() {
        let chains: [Int] = selectedChain == .all ? ChainType.allCases.map { $0.customRPC().chainID } : [selectedChain.getChainId()]
        service.getListApproval(address: address, chainIds: chains) { [weak self] response in
            self?.approvals = response?.data?.approvals?.filter { approval in
                return BigInt(approval.amount ?? "0") ?? .zero >= BigInt(10).power(approval.decimals) / BigInt(10).power(6) // Should > 0.000001
            } ?? []
            self?.filteredApprovals = self?.getFilteredApprovals(searchText: self?.searchText ?? "")
                .map { approval in ApprovedTokenItemViewModel(approval: approval) } ?? []
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
    
    func requestRevoke(approval: Approval, setting: TxSettingObject) {
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
        service.getSendApproveERC20TokenEncodeData(spender: spender, value: .zero) { result in
            switch result {
            case .success(let hex):
                service.getTransactionCount(address: self.address) { result in
                    switch result {
                    case .success(let count):
                        let signResult = KNGeneralProvider.shared.signTransactionData(address: AppState.shared.currentAddress, tokenAddress: tokenAddress, nonce: count, data: hex, gasPrice: gasPrice, gasLimit: setting.gasLimit)
                        switch signResult {
                        case .success(let signature):
                            KNGeneralProvider.shared.sendSignedTransactionData(signature.0) { result in
                                switch result {
                                case .success(let hash):
                                    print(hash)
                                case .failure:
                                    ()
                                }
                            }
                        case .failure:
                            ()
                        }
                    case .failure:
                        ()
                    }
                }
            case .failure(let error):
                ()
            }
        }
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
    
}
