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

class TxHistoryViewModel {
    
    var rows: [TxHistoryRowType] = []
    var txs: [TxRecord] = []
    
    var allChainIds: [Int] {
        return ChainType.getAllChain().map { $0.getChainId() }
    }
    
    var walletAddress: String {
        return AppState.shared.currentAddress.addressString
    }
    
    var isLoading = false
    var canLoadMore = true
    
    private let historyService = HistoryService()
    var onRowsUpdated: (() -> ())?
    
    func load(shouldReset: Bool) {
        let endTime = shouldReset ? nil : txs.last?.blockTime
        isLoading = true
        historyService.getTxHistory(walletAddress: walletAddress, tokenAddress: nil, chainIds: allChainIds, limit: 20, endTime: endTime) { [weak self] txRecords in
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
        if let transfers = tx.tokenTransfers {
            let viewModels = transfers.map { transfer in
                return TxHistoryTokenCellViewModel(transfer: transfer)
            }
            rows.append(contentsOf: viewModels.map { TxHistoryRowType.tokenChange(viewModel: $0) })
        }
        rows.append(.footer(viewModel: .init(tx: tx)))
        return rows
    }
}
