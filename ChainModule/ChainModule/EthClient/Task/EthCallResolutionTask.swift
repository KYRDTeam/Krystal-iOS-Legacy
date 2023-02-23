//
//  EthCallResolutionTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthCallResolutionTask: TaskProtocol {
    let client: EthereumClientProtocol
    let transaction: EthereumTransaction
    let resolution: CallResolution
    let block: EthereumBlock
    
    init(client: EthereumClientProtocol, transaction: EthereumTransaction, resolution: CallResolution, block: EthereumBlock) {
        self.client = client
        self.transaction = transaction
        self.resolution = resolution
        self.block = block
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_call(transaction, resolution: resolution, block: block) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
