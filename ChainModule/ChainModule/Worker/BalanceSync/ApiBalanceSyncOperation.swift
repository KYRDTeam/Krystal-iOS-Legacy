//
//  ApiBalanceSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

public class ApiBalanceSyncOperation: BalanceSyncOperation {
    let address: String
    let chainIDs: [Int]
    let tokenService = TokenService()
    
    init(address: String, chainIDs: [Int]) {
        self.address = address
        self.chainIDs = chainIDs
    }
    
    override func execute(completion: @escaping () -> ()) {
        var formattedAddresses: [String] = []
        chainIDs.forEach { chainID in
            if let addressPrefix = ChainDB.shared.getConfig(chainID: chainID, key: kChainAddressPrefix), !addressPrefix.isEmpty {
                formattedAddresses.append(addressPrefix + ":" + address)
            } else {
                formattedAddresses.append(address)
            }
        }
        tokenService.getBalance(chainIDs: chainIDs, addresses: formattedAddresses) { chainBalanceModels in
            let tokenBalances = chainBalanceModels.flatMap { chainBalanceModel in
                return chainBalanceModel.balances.map {
                    return TokenBalanceEntity(chainID: chainBalanceModel.chainId, tokenAddress: $0.token.address, walletAddress: $0.userAddress, balance: $0.balance)
                }
            }
            TokenBalanceDB.shared.save(balances: tokenBalances)
            completion()
        }
    }
    
}
