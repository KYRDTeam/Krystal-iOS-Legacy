//
//  EthGetSingleTopicLogsTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthGetSingleTopicLogsTask: TaskProtocol {
    let client: EthereumClientProtocol
    let addresses: [EthereumAddress]?
    var topics: Topics?
    var fromBlock: EthereumBlock
    var toBlock: EthereumBlock
    
    init(client: EthereumClientProtocol, addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock) {
        self.client = client
        self.addresses = addresses
        self.topics = topics
        self.fromBlock = fromBlock
        self.toBlock = toBlock
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        Task {
            do {
                let result = try await client.getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
}
