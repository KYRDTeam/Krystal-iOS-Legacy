//
//  EthGetBlockByNumberTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthGetBlockByNumberTask: TaskProtocol {
    let client: EthereumClientProtocol
    let block: EthereumBlock
    
    init(client: EthereumClientProtocol, block: EthereumBlock) {
        self.client = client
        self.block = block
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_getBlockByNumber(block) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
