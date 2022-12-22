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
    
    var allChainIds: [Int] {
        return ChainType.getAllChain().map { $0.getChainId() }
    }
    
    var walletAddress: String {
        return AppState.shared.currentAddress.addressString
    }
    
    private let historyService = HistoryService()
    var onRowsUpdated: (() -> ())?
    
    func loadTxHistory(endTime: Int?) {
        historyService.getTxHistory(walletAddress: walletAddress, tokenAddress: nil, chainIds: allChainIds, limit: 20, endTime: nil) { [weak self] txRecords in
            guard let self = self else { return }
            self.rows.append(contentsOf: txRecords.flatMap { self.constructRows(tx: $0) })
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
