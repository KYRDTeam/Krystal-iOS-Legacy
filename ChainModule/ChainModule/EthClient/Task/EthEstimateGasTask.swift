//
//  EthEstimateGasTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthEstimateGasTask: TaskProtocol {
    let transaction: EthereumTransaction
    let client: EthereumClientProtocol
    
    init(client: EthereumClientProtocol, transaction: EthereumTransaction) {
        self.client = client
        self.transaction = transaction
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_estimateGas(transaction) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
