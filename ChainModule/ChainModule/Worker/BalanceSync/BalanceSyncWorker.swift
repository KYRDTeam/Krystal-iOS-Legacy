//
//  BalanceSyncWorker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import web3
import KrystalWallets

public class BalanceSyncWorker: Worker {
    let tokens: [Token]
    let address: KAddress
    
    public init(tokens: [Token], address: KAddress) {
        self.tokens = tokens
        self.address = address
        super.init(operations: [])
    }
    
    override public func prepare(completion: @escaping () -> ()) {
        start {
            self.operations = self.createSyncOperations(tokens: self.tokens)
            completion()
        }
    }
    
    func createSyncOperations(tokens: [Token]) -> [BalanceSyncOperation] {
        let group = Dictionary(grouping: tokens, by: { $0.chainID })
        var operations = [BalanceSyncOperation]()
        var apiSupportedChainIDs: [Int] = []
        
        group.keys.forEach { chainID in
            if address.addressType == ChainDB.shared.getChain(byID: chainID)?.addressType {
                let isBalanceApiEnabled = ChainDB.shared.isConfigEnabled(chainID: chainID, key: kChainBalanceSupported)
                let multicallAddress = ChainDB.shared.getSmartContracts(chainID: chainID, type: kSmartContractTypeMulticall).first?.address
                let multicallV2Address = ChainDB.shared.getSmartContracts(chainID: chainID, type: kSmartContractTypeMulticallV2).first?.address
                let rpcUrls = ChainDB.shared.getUrls(chainID: chainID, type: kChainRpcUrlType).sorted { lhs, rhs in
                    return lhs.priority < rhs.priority
                }.prefix(3).map(\.url)
                let chainTokens = group[chainID]?.filter { !$0.isNativeToken } ?? []
                let clients = rpcUrls.compactMap { EthereumClientFactory.shared.client(forUrl: $0) }
                
                if isBalanceApiEnabled {
                    apiSupportedChainIDs.append(chainID)
                } else if clients.count > 0 {
                    if let multicallV2Address = multicallV2Address {
                        operations.append(
                            MulticallV2BalanceSyncOperation(ethClients: clients, walletAddress: address.addressString, tokens: chainTokens.map(\.address), chainID: chainID, multicallAddress: multicallV2Address)
                        )
                    } else if let multicallAddress = multicallAddress {
                        operations.append(
                            MulticallBalanceSyncOperation(ethClients: clients, walletAddress: address.addressString, tokens: chainTokens.map(\.address), chainID: chainID, multicallAddress: multicallAddress)
                        )
                    } else {
                        operations.append(contentsOf: chainTokens.map {
                            return SingleCallBalanceSyncOperation(ethClients: clients, chainID: chainID, walletAddress: address.addressString, tokenAddress: $0.address)
                        })
                    }
                }
                if clients.count > 0 {
                    if group[chainID]?.contains(where: { $0.isNativeToken }) ?? false {
                        operations.append(NativeTokenBalanceSyncOperation(ethClients: clients, chainID: chainID, walletAddress: address.addressString))
                    }
                }
            }
        }
        if !apiSupportedChainIDs.isEmpty {
            operations.append(ApiBalanceSyncOperation(address: address.addressString, chainIDs: apiSupportedChainIDs))
        }
        return operations
    }
    
}
