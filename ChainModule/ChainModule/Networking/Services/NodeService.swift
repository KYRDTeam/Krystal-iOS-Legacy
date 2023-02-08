//
//  NodeService.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import BigInt
import Result
import JSONRPCKit
import APIKit

class NodeBalanceService {
    
    var web3Client: Web3Client?
    var rpcUrl: String
    
    init(rpcUrl: String) {
        self.rpcUrl = rpcUrl
        self.web3Client = Web3ClientFactory.shared.web3Instance(forUrl: rpcUrl)
    }
    
    func getTokenBalances(walletAddress: String, tokenAddresses: [String], smartContract: String, completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
        getTokenBalancesEncodeData(walletAddress: walletAddress, tokenAddresses: tokenAddresses) { result in
            switch result {
            case .success(let data):
                let request = EtherServiceRequest(batch: BatchFactory().create(CallRequest(to: smartContract, data: data)), rpcUrl: self.rpcUrl)
                Session.send(request) { result in
                    switch result {
                    case .success(let balance):
                        self.getTokenBalancesDecodeData(balance: balance, completion: completion)
                    case .failure(let error):
                        completion(.failure(AnyError(error)))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getTokenBalance(tokenAddress: String, walletAddress: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
        guard !walletAddress.isEmpty else {
            completion(.success(BigInt(0)))
            return
        }
        getTokenBalanceEncodeData(walletAddress: walletAddress) { encodeResult in
            switch encodeResult {
            case .success(let data):
                let request = EtherServiceRequest(batch: BatchFactory().create(CallRequest(to: tokenAddress, data: data)), rpcUrl: self.rpcUrl)
                Session.send(request) { result in
                    switch result {
                    case .success(let balance):
                        self.getTokenBalanceDecodeData(balance: balance, completion: completion)
                    case .failure(let error):
                        completion(.failure(AnyError(error)))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getQuoteBalance(walletAddress: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
        let request = EtherServiceRequest(batch: BatchFactory().create(BalanceRequest(address: walletAddress)), rpcUrl: rpcUrl)
        Session.send(request) { result in
            switch result {
            case .success(let balance):
                completion(.success(balance))
            case .failure(let error):
                completion(.failure(AnyError(error)))
            }
        }
    }
    
    func getTokenBalanceEncodeData(walletAddress: String, completion: @escaping (Result<String, AnyError>) -> Void) {
        let request = GetERC20BalanceEncode(address: walletAddress)
        web3Client?.request(request: request) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(AnyError(error)))
            }
        }
    }
    
    func getTokenBalanceDecodeData(balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
        if balance == "0x" {
            completion(.success(BigInt(0)))
            return
        }
        let request = GetERC20BalanceDecode(data: balance)
        web3Client?.request(request: request) { result in
            switch result {
            case .success(let res):
                completion(.success(BigInt(res) ?? BigInt()))
            case .failure(let error):
                completion(.failure(AnyError(error)))
            }
        }
    }
    
    func getTokenBalancesEncodeData(walletAddress: String, tokenAddresses: [String], completion: @escaping (Result<String, AnyError>) -> Void) {
        let request = GetMultipleERC20BalancesEncode(address: walletAddress, tokens: tokenAddresses)
        web3Client?.request(request: request) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(AnyError(error)))
            }
        }
    }
    
    func getTokenBalancesDecodeData(balance: String, completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
        let request = GetMultipleERC20BalancesDecode(data: balance)
        web3Client?.request(request: request) { result in
            switch result {
            case .success(let data):
                completion(.success(data.map { BigInt($0) ?? .zero }))
            case .failure(let error):
                completion(.failure(AnyError(error)))
            }
        }
    }
    
}
