//
//  HistoryStatsViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 05/01/2023.
//

import Foundation
import BaseWallet
import Services
import BigInt

public class HistoryStatsViewModel {
    
    var chain: ChainType
    var address: String
    let service = HistoryService()
    var txStats: [String: ChainTxStats] = [:]
    
    var chainIds: [Int] {
        switch chain {
        case .all:
            return ChainType.getAllChain().map { $0.getChainId() }
        default:
            return [chain.getChainId()]
        }
    }
    
    var cellTypes: [TxStatsCellType] = []
    var onTxStatsUpdated: (() -> ())?
    
    public init(chain: ChainType, address: String) {
        self.chain = chain
        self.address = address
    }
    
    func getTxStats() {
        service.getTxStats(address: address, chainIds: chainIds) { [weak self] data in
            self?.txStats = data?.statsByChain ?? [:]
            self?.updateCellTypes()
            self?.onTxStatsUpdated?()
        }
    }
    
    func updateCellTypes() {
        let cellTypes: [TxStatsCellType] = {
            switch chain {
            case .all:
                let totalTxs: Int = txStats.reduce(0) { $0 + $1.value.totalTx }
                let totalGasSpentUsd: Double = txStats.reduce(0) { $0 + $1.value.totalGasSpentUsd }
                let totalVolumeUsd: Double = txStats.reduce(0) { $0 + $1.value.totalVolumeUsd }
                return [
                    .totalTx(totalTxs),
                    .totalGasFee(totalGasSpentUsd),
                    .totalVolume(totalVolumeUsd)
                ]
            default:
                let chainIDString = "\(chain.getChainId())"
                let totalTxs: Int = txStats[chainIDString]?.totalTx ?? 0
                let totalGasSpentUsd: Double = txStats[chainIDString]?.totalGasSpentUsd ?? 0
                let totalVolumeUsd: Double = txStats[chainIDString]?.totalVolumeUsd ?? 0
                return [
                    .totalTx(totalTxs),
                    .totalGasFee(totalGasSpentUsd),
                    .totalVolume(totalVolumeUsd)
                ]
            }
        }()
        self.cellTypes = cellTypes
    }
    
}
