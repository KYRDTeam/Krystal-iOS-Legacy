//
//  EtherServiceRequest.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import JSONRPCKit
import APIKit

struct EtherServiceRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
    let batch: Batch
    let rpcUrl: String
    
    typealias Response = Batch.Responses
    
    var baseURL: URL {
        return URL(string: rpcUrl)!
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
    
    init(batch: Batch, rpcUrl: String) {
        self.batch = batch
        self.rpcUrl = rpcUrl
    }
    
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        return try batch.responses(from: object)
    }
}
