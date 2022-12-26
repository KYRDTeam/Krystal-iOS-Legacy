//
//  EthereumServiceRequest.swift
//  Services
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import APIKit
import JSONRPCKit
import BaseWallet

struct EtherServiceRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
    let batch: Batch
    let chain: ChainType
    
    typealias Response = Batch.Responses
    
    var baseURL: URL {
        // Change to KyberNetwork endpoint
        if let path = URL(string: chain.customRPC().endpoint + NodeConfig.nodeEndpoint) {
            return path
        }
        let config = RPCConfig()
        return config.rpcURL
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return ""
    }
    
    var parameters: Any? {
        return batch.requestObject
    }
    
    init(batch: Batch, chain: ChainType) {
        self.batch = batch
        self.chain = chain
    }
    
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        return try batch.responses(from: object)
    }
}

struct EtherServiceKyberRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
    let batch: Batch
    let chain: ChainType
    
    typealias Response = Batch.Responses
    
    var baseURL: URL {
        // Change to KyberNetwork endpoint
        if let path = URL(string: chain.customRPC().endpointKyber + NodeConfig.nodeEndpoint) {
            return path
        }
        let config = RPCConfig()
        return config.rpcURL
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return ""
    }
    
    var parameters: Any? {
        return batch.requestObject
    }
    
    init(batch: Batch, chain: ChainType) {
        self.batch = batch
        self.chain = chain
    }
    
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        return try batch.responses(from: object)
    }
}

struct EtherServiceAlchemyRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
    let batch: Batch
    let chain: ChainType
    
    typealias Response = Batch.Responses
    
    var baseURL: URL {
        // Change to KyberNetwork endpoint
        if let path = URL(string: chain.customRPC().endpointAlchemy + NodeConfig.nodeEndpoint) {
            return path
        }
        let config = RPCConfig()
        return config.rpcURL
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return ""
    }
    
    var parameters: Any? {
        return batch.requestObject
    }
    
    init(batch: Batch, chain: ChainType) {
        self.batch = batch
        self.chain = chain
    }
    
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        return try batch.responses(from: object)
    }
}
