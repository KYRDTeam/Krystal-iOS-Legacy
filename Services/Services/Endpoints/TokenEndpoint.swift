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
  case getCommonBaseToken(chainPath: String)
  case getPoolList(tokenAddress: String, chainID: Int, limit: Int)
  case getChartData(chainPath: String, address: String, quote: String, from: Int, to: Int)
  case getSearchToken(chainPath: String, address: String, query: String, orderBy: String)
}

extension TokenEndpoint: TargetType {
  
  var baseURL: URL {
    return URL(string: ServiceConfig.baseAPIURL)!
  }
  
  var path: String {
    switch self {
    case .getTokenDetail(let chainPath, _):
      return "/\(chainPath)/v1/token/tokenDetails"
    case .getCommonBaseToken(let chainPath):
      return "/\(chainPath)/v1/token/commonBase"
    case .getPoolList:
      return "/all/v1/pool/list"
    case .getChartData(let chainPath, _, _, _, _):
      return "/\(chainPath)/v1/market/priceSeries"
    case .getSearchToken(let chainPath, _, _, _):
      return "/\(chainPath)/v1/token/search"
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
    case .getChartData(_, let address, let quote, let from, let to):
      let json: [String: Any] = [
        "token": address,
        "quoteCurrency": quote,
        "from": from,
        "to": to
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getSearchToken(_, let address, let query, let orderBy):
      var json: [String: Any] = [
        "query": query,
        "orderBy": orderBy,
        "limit": 50,
        "tags": "PROMOTION,VERIFIED,UNVERIFIED"
      ]
      if !address.isEmpty {
        json["address"] = address
      }
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    }
  }
  
  var headers: [String : String]? {
    return [:]
  }
  
}
