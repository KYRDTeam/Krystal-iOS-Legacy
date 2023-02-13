//
//  MulticallBalanceSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import web3

class MulticallBalanceSyncOperation: BalanceSyncOperation {
    let chainID: Int
    let rpcUrl: String
    let multicallAddress: String
    let tokens: [String]
    let walletAddress: String
    var ethClient: EthereumHttpClient!
    var multicall: Multicall!
    
    init(walletAddress: String, tokens: [String], chainID: Int, rpcUrl: String, multicallAddress: String) {
        self.ethClient = EthereumHttpClient(url: URL(string: rpcUrl)!)
        self.multicall = Multicall(client: self.ethClient)
        self.walletAddress = walletAddress
        self.chainID = chainID
        self.rpcUrl = rpcUrl
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
        multicall.aggregate(calls: aggregator.calls, contract: EthereumAddress(multicallAddress)) { result in
            TokenDB.shared.save(balances: balances)
            completion()
        }
    }
    
}
