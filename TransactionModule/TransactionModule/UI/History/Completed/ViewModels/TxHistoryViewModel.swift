//
//  TxHistoryViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 21/12/2022.
//

import Foundation
import UIKit
import Services
import BaseWallet
import AppState
import BigInt

class TxHistoryViewModel {
    
    var rows: [TxHistoryRowType] = []
    var txs: [TxRecord] = []
    
    var currentChain: ChainType = .all
    
    var chainIds: [Int] {
        return currentChain == .all ? ChainType.getAllChain().map { $0.getChainId() } : [currentChain.getChainId()]
    }
    
    var walletAddress: String {
        return AppState.shared.currentAddress.addressString
    }
    
    var selectedFilterToken: AdvancedSearchToken?
    
    var isLoading = false
    var canLoadMore = true
    
    private let historyService = HistoryService()
    var onRowsUpdated: (() -> ())?
    
    func load(shouldReset: Bool) {
        isLoading = true
        let endTime = shouldReset ? nil : txs.last?.blockTime
        let filterChainIds = selectedFilterToken == nil ? self.chainIds : [selectedFilterToken!.chainId]
        historyService.getTxHistory(walletAddress: walletAddress, tokenAddress: selectedFilterToken?.id, chainIds: filterChainIds, limit: 20, endTime: endTime) { [weak self] txRecords in
            guard let self = self else { return }
            self.isLoading = false
            if shouldReset { // Clear the list
                self.txs = []
                self.rows = []
            }
            self.canLoadMore = !txRecords.isEmpty
            self.txs.append(contentsOf: txRecords)
            var originalDate = Date(timeIntervalSince1970: 0)
            txRecords.forEach { record in
                let recordDate = Date(timeIntervalSince1970: Double(record.blockTime))
                if Calendar.current.startOfDay(for: recordDate) != Calendar.current.startOfDay(for: originalDate) {
                    originalDate = Calendar.current.startOfDay(for: recordDate)
                    self.rows.append(.date(date: recordDate))
                }
                self.rows.append(contentsOf: self.constructRows(tx: record))
            }
            self.onRowsUpdated?()
        }
    }
    
    func constructRows(tx: TxRecord) -> [TxHistoryRowType] {
        var rows: [TxHistoryRowType] = []
        rows.append(.header(viewModel: .init(tx: tx)))
        let dict = Dictionary(grouping: tx.tokenTransfers ?? []) { element in
            return element.token?.symbol
        }
        let keys = dict.keys.compactMap { $0 }.sorted()
        keys.forEach { key in
            let txs = dict[key] ?? []
            let amount: BigInt = txs.reduce(.zero) { $0 + (BigInt($1.amount) ?? .zero) }
            let usdValue: Double = txs.reduce(0) { $0 + $1.historicalValueInUsd }
            if let token = txs.first?.token, token.isValid, amount != .zero {
                let viewModel = TxHistoryTokenCellViewModel(token: token, amount: amount, usdValueInUsd: usdValue, isApproval: false)
                rows.append(TxHistoryRowType.tokenChange(viewModel: viewModel))
            }
        }
        if let tokenApproval = tx.tokenApproval, let token = tokenApproval.token, token.isValid, let amount = BigInt(tokenApproval.amount), amount > 0 {
            let viewModel = TxHistoryTokenCellViewModel(token: token, amount: amount, usdValueInUsd: 0, isApproval: true)
            rows.append(TxHistoryRowType.tokenChange(viewModel: viewModel))
        }
        rows.append(.footer(viewModel: .init(tx: tx)))
        return rows
    }
}

fileprivate extension TokenInfo {
    
    var isValid: Bool {
        return !symbol.isEmpty && decimals > 0
    }
    
}
