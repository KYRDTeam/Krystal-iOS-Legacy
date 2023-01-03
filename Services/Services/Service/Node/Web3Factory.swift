//
//  Web3Factory.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BaseWallet

class Web3Factory {
    
    static let shared = Web3Factory()
    
    private init() {}
    
    var web3s: [ChainType: Web3Swift] = [:]
    
    func web3Instance(forChain chain: ChainType) -> Web3Swift? {
        if let instance = web3s[chain] {
            return instance
        }
        guard let url = URL(string: chain.customRPC().endpoint + NodeConfig.nodeEndpoint) else {
            return nil
        }
        let web3 = Web3Swift(url: url)
        web3s[chain] = web3
        return web3
    }
    
}
