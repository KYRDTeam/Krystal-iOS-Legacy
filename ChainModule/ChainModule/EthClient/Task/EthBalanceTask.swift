//
//  EthBalanceTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthBalanceTask: TaskProtocol {
    let address: EthereumAddress
    let block: EthereumBlock = .Latest
    let client: EthereumClientProtocol
    
    init(client: EthereumClientProtocol, address: EthereumAddress) {
        self.client = client
        self.address = address
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_getBalance(address: address, block: block) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
