//
//  MarketEndpoint.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 13/07/2022.
//

import Foundation
import Moya

enum MarketEndpoint {
  case overview(chainPath: String, quotes: [String])
}

extension MarketEndpoint: TargetType {
  
  var baseURL: URL {
    return URL(string: KNEnvironment.default.krystalEndpoint)!
  }
  
  var path: String {
    switch self {
    case .overview(let chainPath, _):
      return "/\(chainPath)/v1/market/overview"
    }
  }
  
  var method: Moya.Method {
    return .get
  }
  
  var sampleData: Data {
    return Data()
  }
  
  var task: Task {
    switch self {
    case .overview(_, let quotes):
      let params: [String: Any] = ["sparkline": false, "quoteCurrencies": quotes]
      return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }
  }
  
  var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.bvi",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
  
}
