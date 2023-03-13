//
//  UserEndpoint.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 21/09/2022.
//

import Foundation
import Moya

enum UserEndpoint {
    case connectEvm(address: String, signature: String)
    case connectSolana(address: String, signature: String)
    case submitTransaction(transaction: [String: Any])
}

extension UserEndpoint: TargetType {
  
  var baseURL: URL {
      return URL(string: KNEnvironment.default.userAPIURL)!
  }
  
  var path: String {
      switch self {
      case .connectEvm:
          return "/v1/users/connect/evm"
      case .connectSolana:
          return "/v1/users/connect/solana"
      case .submitTransaction:
          return "/v1/transactions"
      }
  }
  
  var method: Moya.Method {
    return .post
  }
  
  var sampleData: Data {
    return Data()
  }
  
  var task: Task {
    switch self {
    case .connectEvm(let address, let signature):
          let params: [String: Any] = [
            "address": address,
            "signature": signature,
            "timestamp": Int(Date().timeIntervalSince1970)
          ]
          return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    case .connectSolana(let address, let signature):
        let params: [String: Any] = [
          "address": address,
          "signature": signature,
          "timestamp": Int(Date().timeIntervalSince1970)
        ]
        return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    case .submitTransaction(transaction: let transaction):
        return .requestParameters(parameters: transaction, encoding: JSONEncoding.default)
    }
  }
  
  var headers: [String: String]? {
      return ["x-krystal-platform": "ios"]
  }
  
}
