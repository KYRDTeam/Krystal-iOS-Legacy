//
//  EthGetLogsTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthGetLogsTask: TaskProtocol {
    let client: EthereumClientProtocol
    let addresses: [EthereumAddress]?
    var topics: [String?]?
    var fromBlock: EthereumBlock
    var toBlock: EthereumBlock
    
    init(client: EthereumClientProtocol, addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) {
        self.client = client
        self.addresses = addresses
        self.topics = topics
        self.fromBlock = fromBlock
        self.toBlock = toBlock
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
