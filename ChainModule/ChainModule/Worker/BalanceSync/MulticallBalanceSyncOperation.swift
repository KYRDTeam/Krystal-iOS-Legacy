//
//  MulticallBalanceSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

class MulticallBalanceSyncOperation: BalanceSyncOperation {
    let chainID: Int
    let rpcUrl: String
    let multicallAddress: String
    let tokens: [String]
    let walletAddress: String
    
    init(walletAddress: String, tokens: [String], chainID: Int, rpcUrl: String, multicallAddress: String) {
        self.walletAddress = walletAddress
        self.chainID = chainID
        self.rpcUrl = rpcUrl
        self.multicallAddress = multicallAddress
        self.tokens = tokens
    }
    
    override func execute(completion: @escaping () -> ()) {
        NodeBalanceService(rpcUrl: rpcUrl).getTokenBalances(walletAddress: walletAddress, tokenAddresses: tokens, smartContract: multicallAddress) { result in
            switch result {
            case .success(let balances):
                if balances.count < self.tokens.count {
                    completion()
                    return
                }
                let balances = self.tokens.enumerated().map { index, token in
                    return TokenBalanceEntity(chainID: self.chainID,
                                              tokenAddress: token,
                                              walletAddress: self.walletAddress,
                                              balance: balances[index].description)
                }
                TokenDB.shared.save(balances: balances)
                completion()
            case .failure:
                completion()
            }
        }
    }
    
}
