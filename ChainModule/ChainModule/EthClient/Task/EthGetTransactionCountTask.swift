//
//  EthGetTransactionCountTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthGetTransactionCountTask: TaskProtocol {
    let block: EthereumBlock
    let address: EthereumAddress
    let client: EthereumClientProtocol
    
    init(client: EthereumClientProtocol, address: EthereumAddress, block: EthereumBlock = .Latest) {
        self.client = client
        self.block = block
        self.address = address
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_getTransactionCount(address: address, block: block) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
