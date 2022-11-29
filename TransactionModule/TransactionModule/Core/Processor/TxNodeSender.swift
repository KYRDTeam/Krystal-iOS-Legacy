//
//  TxNodeSender.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/11/2022.
//

import Foundation
import Result
import BaseWallet
import Services
import JSONRPCKit
import APIKit

public class TxNodeSender: TxNodeSenderProtocol {
    
    public init() {
        
    }
    
    func getTxNodeURLs(chain: ChainType) -> [URL] {
        return [
            chain.customRPC().endpoint,
            chain.customRPC().endpointKyber,
            chain.customRPC().endpointAlchemy,
        ].compactMap(URL.init)
    }
    
    public func sendTx(data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void) {
        var error: Error?
        var transactionID: String?
        var hasCompletionCalled: Bool = false
        let group = DispatchGroup()
        let nodeURLs = getTxNodeURLs(chain: chain)
        nodeURLs.forEach { url in
            group.enter()
            sendRawTransaction(url: url, data: data, chain: chain) { result in
                switch result {
                case .success(let ID):
                    transactionID = ID
                    if !hasCompletionCalled {
                        hasCompletionCalled = true
                        completion(.success(ID))
                    }
                case .failure(let err):
                    // code=3840 is the invalid JSON response case (when timeout or cannot connect)
                    if case let APIKit.SessionTaskError.responseError(apiKitError) = err.error, apiKitError.code == 3840 {
                        if error == nil {
                            error = err
                        }
                    } else {
                        error = err
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            if let id = transactionID {
                if !hasCompletionCalled { completion(.success(id)) }
            } else if let err = error {
                completion(.failure(AnyError(err)))
            }
        }
    }
    
    func sendRawTransaction(url: URL, data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void) {
        let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
        let request = EtherNodeRequest(batch: batch, chain: chain, baseURL: url)
        Session.send(request) { result in
            switch result {
            case .success(let transactionID):
                completion(.success(transactionID))
            case .failure(let error):
                completion(.failure(AnyError(error)))
            }
        }
    }
    
}
