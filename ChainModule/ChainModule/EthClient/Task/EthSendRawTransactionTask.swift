//
//  EthSendRawTransactionTask.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3

class EthSendRawTransactionTask: TaskProtocol {
    let transaction: EthereumTransaction
    let account: EthereumAccountProtocol
    let client: EthereumClientProtocol
    
    init(client: EthereumClientProtocol, transaction: EthereumTransaction, account: EthereumAccountProtocol) {
        self.client = client
        self.transaction = transaction
        self.account = account
    }
    
    func handle(completion: @escaping ((Result<Any, Error>) -> ())) {
        client.eth_sendRawTransaction(transaction, withAccount: account) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
