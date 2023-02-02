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
    
    init(chainID: Int, rpcUrl: String, multicallAddress: String, tokens: [String]) {
        self.chainID = chainID
        self.rpcUrl = rpcUrl
        self.multicallAddress = multicallAddress
        self.tokens = tokens
    }
    
    override func execute(completion: @escaping () -> ()) {
        
    }
    
}
