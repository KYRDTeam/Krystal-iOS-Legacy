//
//  EthereumClientFactory.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthereumClientFactory {
    static let shared = EthereumClientFactory()
    
    private init() {}
    
    var clients: [String: EthereumHttpClient] = [:]
    
    func client(forUrl urlString: String) -> EthereumHttpClient? {
        if let instance = clients[urlString] {
            return instance
        }
        guard let url = URL(string: urlString) else {
            return nil
        }
        let client = EthereumHttpClient(url: url)
        clients[urlString] = client
        return client
    }
    
}
