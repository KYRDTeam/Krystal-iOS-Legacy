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
}

extension UserEndpoint: TargetType {
  
  var baseURL: URL {
    return URL(string: KNEnvironment.default.userAPIURL)!
  }
  
  var path: String {
    return "/v1/users/connect/evm"
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
    }
  }
  
  var headers: [String: String]? {
    return [:]
  }
  
}
