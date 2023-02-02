//
//  Web3ClientFactory.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

class Web3ClientFactory {
    static let shared = Web3ClientFactory()
    
    private init() {}
    
    var web3Clients: [String: Web3Client] = [:]
    
    func web3Instance(forUrl rpcUrl: String) -> Web3Client? {
        if let instance = web3Clients[rpcUrl] {
            return instance
        }
        guard let url = URL(string: rpcUrl) else {
            return nil
        }
        let web3Client = Web3Client(url: url)
        web3Clients[rpcUrl] = web3Client
        return web3Client
    }
}
