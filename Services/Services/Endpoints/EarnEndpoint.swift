//
//  EarnEndpoint.swift
//  Services
//
//  Created by Com1 on 27/10/2022.
//

import Foundation
import Moya
import Utilities

enum EarnEndpoint {
  case listOption(chainId: String?)
  case getEarningBalances(address: String, chainId: String?)
  case getPendingUnstakes(address: String)
  case getEarningOptionDetail(platform: String, earningType: String, chainID: String, tokenAddress: String)
  case buildStakeTx(params: JSONDictionary)
  case buildUnstakeTx(params: JSONDictionary)
}

extension EarnEndpoint: TargetType {
  var baseURL: URL {
    return URL(string: ServiceConfig.baseAPIURL + "/all")!
  }
  
  var path: String {
    switch self {
    case .listOption:
      return "v1/earning/options"
    case .getEarningBalances:
      return "/v1/earning/earningBalances"
    case .getPendingUnstakes:
      return "/v1/earning/pendingUnstakes"
    case .getEarningOptionDetail:
      return "/v1/earning/optionDetail"
    case .buildStakeTx(params: _):
      return "/v1/earning/buildStakeTx"
    case .buildUnstakeTx:
        return "/v1/earning/buildUnstakeTx"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .buildStakeTx, .buildUnstakeTx:
      return .post
    default:
      return .get
    }
  }
  
  var sampleData: Data {
    return Data()
  }
  
  var task: Moya.Task {
    switch self {
    case .listOption(let chainId):
      var json: JSONDictionary = [:]
      if let chainId = chainId {
        json["chainID"] = chainId
      }
      return json.isEmpty ? .requestPlain : .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getEarningBalances(address: let address, chainId: let chainId):
      var json: JSONDictionary = [
        "address": address
      ]
      if let chainId = chainId {
        json["chainId"] = chainId
      }  
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getPendingUnstakes(address: let address):
      var json: JSONDictionary = [
        "address": address
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getEarningOptionDetail(platform: let platform, earningType: let earningType, chainID: let chainID, tokenAddress: let tokenAddress):
      var json: JSONDictionary = [
        "platform": platform,
        "earningType": earningType,
        "chainId": chainID,
        "tokenAddress": tokenAddress
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .buildStakeTx(params: let params):
      return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    case .buildUnstakeTx(params: let params):
      return .requestParameters(parameters: params, encoding: JSONEncoding.default)
    }
  }
  
  var headers: [String : String]? {
    var json: [String: String] = ["client": "com.kyrd.krystal.ios"]
    return json
  }
}
