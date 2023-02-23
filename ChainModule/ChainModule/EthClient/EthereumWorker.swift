//
//  EthereumWorker.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation
import web3
import BigInt

class EthereumWorker: TaskWorker, EthereumClientProtocol {
    
    var network: EthereumNetwork? {
        return clients.first?.network
    }
    
    var clients: [EthereumClientProtocol] = []
    
    init(clients: [EthereumClientProtocol]) {
        self.clients = clients
    }

    func eth_gasPrice(completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        let tasks = clients.map(EthGasPriceTask.init)
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! BigUInt))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthBalanceTask(client: $0, address: address) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! BigUInt))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_estimateGas(_ transaction: EthereumTransaction, completionHandler: @escaping (Result<BigUInt, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthEstimateGasTask(client: $0, transaction: transaction) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! BigUInt))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthSendRawTransactionTask(client: $0, transaction: transaction, account: account) }
        asyncWaitSuccess(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! String))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetTransactionCountTask(client: $0, address: address) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! Int))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getTransaction(byHash txHash: String, completionHandler: @escaping (Result<EthereumTransaction, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetTransactionTask(client: $0, hash: txHash) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! EthereumTransaction))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getTransactionReceipt(txHash: String, completionHandler: @escaping (Result<EthereumTransactionReceipt, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetTransactionReceiptTask(client: $0, hash: txHash) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! EthereumTransactionReceipt))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthCallTask(client: $0, transaction: transaction) }
        asyncWaitSuccess(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! String))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func net_version(completionHandler: @escaping (Result<EthereumNetwork, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthNetVersionTask(client: $0) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! EthereumNetwork))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_blockNumber(completionHandler: @escaping (Result<Int, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthBlockNumberTask(client: $0) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! Int))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getCode(address: EthereumAddress, block: EthereumBlock, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetCodeTask(client: $0, address: address, block: block) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! String))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_call(_ transaction: EthereumTransaction, resolution: CallResolution, block: EthereumBlock, completionHandler: @escaping (Result<String, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthCallResolutionTask(client: $0, transaction: transaction, resolution: resolution, block: block) }
        asyncWaitSuccess(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! String))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetLogsTask(client: $0, addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! [EthereumLog]))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetMultipleTopicLogsTask(client: $0, addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! [EthereumLog]))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func eth_getBlockByNumber(_ block: EthereumBlock, completionHandler: @escaping (Result<EthereumBlockInfo, EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetBlockByNumberTask(client: $0, block: block) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! EthereumBlockInfo))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock, completionHandler: @escaping (Result<[EthereumLog], EthereumClientError>) -> Void) {
        let tasks = clients.map { EthGetSingleTopicLogsTask(client: $0, addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) }
        asyncWaitFastest(handlers: tasks) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data as! [EthereumLog]))
            case .failure(let error):
                completionHandler(.failure(error as! EthereumClientError))
            }
        }
    }
    
    func net_version() async throws -> EthereumNetwork {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<EthereumNetwork, Error>) in
            net_version { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_gasPrice() async throws -> BigUInt {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_gasPrice { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_blockNumber() async throws -> Int {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<Int, Error>) in
            eth_blockNumber { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getBalance(address: EthereumAddress, block: EthereumBlock) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_getBalance(address: address, block: block) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getCode(address: EthereumAddress, block: EthereumBlock) async throws -> String {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<String, Error>) in
            eth_getCode(address: address, block: block) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_estimateGas(_ transaction: EthereumTransaction) async throws -> BigUInt {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<BigUInt, Error>) in
            eth_estimateGas(transaction) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_sendRawTransaction(_ transaction: EthereumTransaction, withAccount account: EthereumAccountProtocol) async throws -> String {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<String, Error>) in
            eth_sendRawTransaction(transaction, withAccount: account) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getTransactionCount(address: EthereumAddress, block: EthereumBlock) async throws -> Int {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<Int, Error>) in
            eth_getTransactionCount(address: address, block: block) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getTransaction(byHash txHash: String) async throws -> EthereumTransaction {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<EthereumTransaction, Error>) in
            eth_getTransaction(byHash: txHash) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<EthereumTransactionReceipt, Error>) in
            eth_getTransactionReceipt(txHash: txHash) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_call(_ transaction: EthereumTransaction, block: EthereumBlock) async throws -> String {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<String, Error>) in
            eth_call(transaction, block: block) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_call(_ transaction: EthereumTransaction, resolution: CallResolution, block: EthereumBlock) async throws -> String {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<String, Error>) in
            eth_call(transaction, resolution: resolution, block: block) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getLogs(addresses: [EthereumAddress]?, topics: [String?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog] {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<[EthereumLog], Error>) in
            eth_getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getLogs(addresses: [EthereumAddress]?, orTopics: [[String]?]?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog] {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<[EthereumLog], Error>) in
            eth_getLogs(addresses: addresses, orTopics: orTopics, fromBlock: fromBlock, toBlock: toBlock) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func eth_getBlockByNumber(_ block: EthereumBlock) async throws -> EthereumBlockInfo {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<EthereumBlockInfo, Error>) in
            eth_getBlockByNumber(block) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func getLogs(addresses: [EthereumAddress]?, topics: Topics?, fromBlock: EthereumBlock, toBlock: EthereumBlock) async throws -> [EthereumLog] {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<[EthereumLog], Error>) in
            getLogs(addresses: addresses, topics: topics, fromBlock: fromBlock, toBlock: toBlock) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
}

