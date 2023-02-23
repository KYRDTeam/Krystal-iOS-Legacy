//
//  MulticallV2BalanceSyncOperation.swift
//  ChainModule
//
//  Created by Tung Nguyen on 14/02/2023.
//

import Foundation
import web3

class MulticallV2BalanceSyncOperation: BalanceSyncOperation {
    let chainID: Int
    let multicallAddress: String
    let tokens: [String]
    let walletAddress: String
    var ethWorker: EthereumWorker
    var multicall: Multicall!
    
    init(ethClients: [EthereumHttpClient], walletAddress: String, tokens: [String], chainID: Int, multicallAddress: String) {
        self.ethWorker = EthereumWorker(clients: ethClients)
        self.multicall = Multicall(client: self.ethWorker)
        self.walletAddress = walletAddress
        self.chainID = chainID
        self.multicallAddress = multicallAddress
        self.tokens = tokens
    }
    
    override func execute(completion: @escaping () -> ()) {
        var aggregator = Multicall.Aggregator()
        var balances: [TokenBalanceEntity] = []
        tokens.forEach { tokenAddress in
            try? aggregator.append(ERC20Functions.balanceOf(contract: EthereumAddress(tokenAddress), account: EthereumAddress(walletAddress)), handler: { output in
                let balance = try? ERC20Responses.balanceResponse(data: output.get())?.value
                balances.append(TokenBalanceEntity(chainID: self.chainID,
                                                   tokenAddress: tokenAddress,
                                                   walletAddress: self.walletAddress,
                                                   balance: (balance ?? .zero).description))
            })
        }
        multicall.tryAggregate(requireSuccess: true, calls: aggregator.calls, contract: EthereumAddress(multicallAddress)) { result in
            TokenBalanceDB.shared.save(balances: balances)
            completion()
        }
    }
    
}
