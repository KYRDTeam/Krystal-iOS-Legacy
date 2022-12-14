// Copyright SIX DAY LLC. All rights reserved.

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
        if let path = URL(string: chain.customRPC().endpoint + KNEnvironment.default.nodeEndpoint) {
        return path
      }
      let config = Config()
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
    
    init(batch: Batch, chain: ChainType = KNGeneralProvider.shared.currentChain) {
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
    if let path = URL(string: chain.customRPC().endpointKyber + KNEnvironment.default.nodeEndpoint) {
      return path
    }
    let config = Config()
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
    
    init(batch: Batch, chain: ChainType = KNGeneralProvider.shared.currentChain) {
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
      if let path = URL(string: chain.customRPC().endpointAlchemy + KNEnvironment.default.nodeEndpoint) {
      return path
    }
    let config = Config()
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
    
    init(batch: Batch, chain: ChainType = KNGeneralProvider.shared.currentChain) {
        self.batch = batch
        self.chain = chain
    }

  func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
    return try batch.responses(from: object)
  }
}
