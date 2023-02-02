//
//  ApiBalanceSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import Services

public class ApiBalanceSyncOperation: BalanceSyncOperation {
    
    let addresses: [Int: String]
    
    init(addresses: [Int: String]) {
        self.addresses = addresses
    }
    
    override func execute(completion: @escaping () -> ()) {
        var formattedAddresses: [String] = []
        addresses.keys.forEach { chainID in
            if let addressPrefix = ChainDB.shared.getConfig(chainID: chainID, key: kChainAddressPrefix), !addressPrefix.isEmpty {
                formattedAddresses.append(addressPrefix + ":" + (addresses[chainID] ?? ""))
            } else {
                formattedAddresses.append(addresses[chainID] ?? "")
            }
        }
        TokenService().getBalance(chainIDs: Array(addresses.keys), addresses: formattedAddresses) { chainBalanceModels in
            let tokenBalances = chainBalanceModels.flatMap { chainBalanceModel in
                return chainBalanceModel.balances.map {
                    return TokenBalanceEntity(chainID: chainBalanceModel.chainId, tokenAddress: $0.token.address, walletAddress: $0.userAddress, balance: $0.balance)
                }
            }
            TokenDB.shared.save(balances: tokenBalances)
            completion()
        }
    }
    
}
