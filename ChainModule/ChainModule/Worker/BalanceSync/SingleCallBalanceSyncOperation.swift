//
//  SingleCallBalanceSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import Services

class SingleCallBalanceSyncOperation: BalanceSyncOperation {
    let chainID: Int
    let rpcUrl: String
    let walletAddress: String
    let tokenAddress: String
    
    init(chainID: Int, rpcUrl: String, walletAddress: String, tokenAddress: String) {
        self.chainID = chainID
        self.rpcUrl = rpcUrl
        self.walletAddress = walletAddress
        self.tokenAddress = tokenAddress
    }
    
    override func execute(completion: @escaping () -> ()) {
        NodeBalanceService(rpcUrl: rpcUrl).getTokenBalance(tokenAddress: tokenAddress, walletAddress: walletAddress) { result in
            switch result {
            case .success(let balance):
                TokenDB.shared.save(
                    balance: TokenBalanceEntity(chainID: self.chainID,
                                                tokenAddress: self.tokenAddress,
                                                walletAddress: self.walletAddress,
                                                balance: balance.description)
                )
            case .failure:
                () // Do nothing
            }
        }
    }
    
}
