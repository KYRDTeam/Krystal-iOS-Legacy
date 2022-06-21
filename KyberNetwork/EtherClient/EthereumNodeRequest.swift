//
//  EthereumNodeRequest.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 20/06/2022.
//

import Foundation
import JSONRPCKit
import APIKit

struct EthereumNodeRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
  typealias Response = Batch.Responses
  
  let batch: Batch
  let nodeURL: URL
  
  init(batch: Batch, nodeURL: URL?) {
    self.batch = batch
    self.nodeURL = nodeURL ?? Config().rpcURL
  }
  
  var baseURL: URL {
    return nodeURL
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

  func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
    return try batch.responses(from: object)
  }
}
