//
//  NativeTokenBalanceSyncOperation.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import RealmSwift

class NativeTokenBalanceSyncOperation: BalanceSyncOperation {
    let chainID: Int
    let rpcUrl: String
    let walletAddress: String
    
    init(chainID: Int, rpcUrl: String, walletAddress: String) {
        self.chainID = chainID
        self.rpcUrl = rpcUrl
        self.walletAddress = walletAddress
    }
    
    override func execute(completion: @escaping () -> ()) {
        NodeBalanceService(rpcUrl: rpcUrl).getQuoteBalance(walletAddress: walletAddress) { result in
            switch result {
            case .success(let balance):
                TokenDB.shared.save(
                    balance: TokenBalanceEntity(chainID: self.chainID,
                                                tokenAddress: defaultNativeTokenAddress,
                                                walletAddress: self.walletAddress,
                                                balance: balance.description)
                )
                if let nativeTokenAddress = ChainDB.shared.getConfig(chainID: self.chainID, key: kChainNativeTokenAddress) {
                    TokenDB.shared.save(
                        balance: TokenBalanceEntity(chainID: self.chainID,
                                                    tokenAddress: nativeTokenAddress,
                                                    walletAddress: self.walletAddress,
                                                    balance: balance.description)
                    )
                }
                completion()
            case .failure:
                completion()
            }
        }
    }
    
}
