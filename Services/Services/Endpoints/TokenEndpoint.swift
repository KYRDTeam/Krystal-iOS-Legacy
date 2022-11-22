//
//  TokenEndpoint.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Moya

enum TokenEndpoint {
  case getTokenDetail(chainPath: String, address: String)
  case getCommonBaseToken
  case getPoolList(tokenAddress: String, chainID: Int, limit: Int)
  case getChartData(chainPath: String, address: String, quote: String, from: Int)
}

extension TokenEndpoint: TargetType {
  
  var baseURL: URL {
    return URL(string: ServiceConfig.baseAPIURL)!
  }
  
  var path: String {
    switch self {
    case .getTokenDetail(let chainPath, _):
      return "/\(chainPath)/v1/token/tokenDetails"
    case .getCommonBaseToken:
      return "/v1/token/commonBase"
    case .getPoolList:
      return "/v1/pool/list"
    case .getChartData(let chainPath, _, _, _):
      return "/\(chainPath)/v1/market/priceSeries"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .getTokenDetail, .getCommonBaseToken, .getPoolList, .getChartData:
      return .get
    }
  }
  
  var sampleData: Data {
    return Data()
  }
  
  var task: Task {
    switch self {
    case .getTokenDetail(_, let address):
      let json: [String: Any] = [
        "address": address
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getCommonBaseToken:
      return .requestPlain
    case .getPoolList(let address, let chainID, let limit):
      let json: [String: Any] = [
        "token": address,
        "chainId": chainID,
        "limit": limit
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getChartData(_, let address, let quote, let from):
      let json: [String: Any] = [
        "token": address,
        "quoteCurrency": quote,
        "from": from
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    }
  }
  
  var headers: [String : String]? {
    return [:]
  }
  
}
