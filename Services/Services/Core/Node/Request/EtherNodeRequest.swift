//
//  EtherNodeRequest.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 28/11/2022.
//

import Foundation
import APIKit
import JSONRPCKit
import BaseWallet

public struct EtherNodeRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
    public let batch: Batch
    public let chain: BaseWallet.ChainType
    public let baseURL: URL
    
    public typealias Response = Batch.Responses

    public var method: HTTPMethod {
        return .post
    }
    
    public var path: String {
        return ""
    }
    
    public var parameters: Any? {
        return batch.requestObject
    }
    
    public init(batch: Batch, chain: ChainType, baseURL: URL) {
        self.batch = batch
        self.chain = chain
        self.baseURL = baseURL
    }
    
    public func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        return try batch.responses(from: object)
    }
}
