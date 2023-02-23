//
//  SingleCallBalanceSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import web3

class SingleCallBalanceSyncOperation: BalanceSyncOperation {
    let chainID: Int
    let walletAddress: String
    let tokenAddress: String
    let ethWorker: EthereumWorker
    
    init(ethClients: [EthereumHttpClient], chainID: Int, walletAddress: String, tokenAddress: String) {
        self.ethWorker = EthereumWorker(clients: ethClients)
        self.chainID = chainID
        self.walletAddress = walletAddress
        self.tokenAddress = tokenAddress
    }
    
    override func execute(completion: @escaping () -> ()) {
        ERC20(client: ethWorker).balanceOf(tokenContract: EthereumAddress(tokenAddress), address: EthereumAddress(walletAddress)) { result in
            switch result {
            case .success(let balance):
                TokenBalanceDB.shared.save(
                    balance: TokenBalanceEntity(chainID: self.chainID,
                                                tokenAddress: self.tokenAddress,
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
