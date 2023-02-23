//
//  NativeTokenBalanceSyncOperation.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import RealmSwift
import web3

class NativeTokenBalanceSyncOperation: BalanceSyncOperation {
    let chainID: Int
    let walletAddress: String
    let ethWorker: EthereumWorker
    
    init(ethClients: [EthereumHttpClient], chainID: Int, walletAddress: String) {
        self.ethWorker = EthereumWorker(clients: ethClients)
        self.chainID = chainID
        self.walletAddress = walletAddress
    }
    
    override func execute(completion: @escaping () -> ()) {
        ethWorker.eth_getBalance(address: EthereumAddress(walletAddress), block: .Latest) { result in
            switch result {
            case .success(let balance):
                TokenBalanceDB.shared.save(
                    balance: TokenBalanceEntity(chainID: self.chainID,
                                                tokenAddress: defaultNativeTokenAddress,
                                                walletAddress: self.walletAddress,
                                                balance: balance.description)
                )
                completion()
            case .failure:
                completion()
            }
        }
    }
    
}
