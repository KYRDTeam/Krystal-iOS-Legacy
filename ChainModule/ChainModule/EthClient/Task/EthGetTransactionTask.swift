//
//  EthGetTransactionTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthGetTransactionTask: TaskProtocol {
    let hash: String
    let client: EthereumClientProtocol
    
    init(client: EthereumClientProtocol, hash: String) {
        self.client = client
        self.hash = hash
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_getTransaction(byHash: hash) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
