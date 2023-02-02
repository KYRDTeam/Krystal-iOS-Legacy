//
//  BalanceSyncWorker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

class BalanceSyncWorker: Worker {
    
    let tokens: [Token]
    let address: String
    
    init(tokens: [Token], address: String) {
        self.tokens = tokens
        self.address = address
        super.init(operations: [])
        self.operations = createSyncOperations(tokens: tokens)
    }
    
    func createSyncOperations(tokens: [Token]) -> [BalanceSyncOperation] {
        let group = Dictionary(grouping: tokens, by: \.chainID)
        var operations = [BalanceSyncOperation]()
        group.keys.forEach { chainID in
            let isBalanceApiEnabled = ChainDB.shared.isConfigEnabled(chainID: chainID, key: kChainBalanceSupported)
            let multicallAddress = ChainDB.shared.getSmartContracts(chainID: chainID).first { $0.type == kSmartContractTypeMulticall }?.address
            let rpcUrl = ChainDB.shared.getUrls(chainID: chainID).min { lhs, rhs in
                return lhs.priority < rhs.priority
            }?.url
            if isBalanceApiEnabled {
                operations.append(ApiBalanceSyncOperation(addresses: [chainID: address]))
            } else if let rpcUrl = rpcUrl {
                if let multicallAddress = multicallAddress {
                    operations.append(
                        MulticallBalanceSyncOperation(chainID: chainID, rpcUrl: rpcUrl, multicallAddress: multicallAddress, tokens: tokens.map(\.address))
                    )
                } else {
                    operations.append(contentsOf: tokens.map {
                        SingleCallBalanceSyncOperation(chainID: chainID, rpcUrl: rpcUrl, walletAddress: address, tokenAddress: $0.address)
                    })
                }
            }
        }
        return operations
    }
    
}
