//
//  EthNetVersionTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthNetVersionTask: TaskProtocol {
    
    let client: EthereumClientProtocol
    
    init(client: EthereumClientProtocol) {
        self.client = client
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.net_version { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
