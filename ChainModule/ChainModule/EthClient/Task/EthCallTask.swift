//
//  EthCallTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthCallTask: TaskProtocol {
    let client: EthereumClientProtocol
    let transaction: EthereumTransaction
    let block: EthereumBlock
    
    init(client: EthereumClientProtocol, transaction: EthereumTransaction, block: EthereumBlock = .Latest) {
        self.client = client
        self.transaction = transaction
        self.block = block
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_call(transaction, block: block) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
