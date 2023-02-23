//
//  EthGetCodeTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthGetCodeTask: TaskProtocol {
    let client: EthereumClientProtocol
    let address: EthereumAddress
    let block: EthereumBlock
    
    init(client: EthereumClientProtocol, address: EthereumAddress, block: EthereumBlock) {
        self.client = client
        self.address = address
        self.block = block
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_getCode(address: address, block: block) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
