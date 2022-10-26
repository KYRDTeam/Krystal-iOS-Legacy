//
//  EarnServices.swift
//  KyberNetwork
//
//  Created by Com1 on 14/10/2022.
//

import Foundation
import Moya
import Result
import Utilities
import Services

enum EarnEndpoint {
  case listOption(chainId: String?)
  case getEarningBalances(address: String)
  case getPendingUnstakes(address: String)
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
    }
  }
  
  var method: Moya.Method {
    return .get
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
    case .getEarningBalances(address: let address):
      var json: JSONDictionary = [
        "address": address
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getPendingUnstakes(address: let address):
      var json: JSONDictionary = [
        "address": address
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    }
  }
  
  var headers: [String : String]? {
    var json: [String: String] = ["client": "com.kyrd.krystal.ios"]
    return json
  }
}

class EarnServices {
  let provider = MoyaProvider<EarnEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
  var currentProcess: Cancellable?

  func getEarnListData(chainId: String?, completion: @escaping ([EarnPoolModel]) -> ()) {
    if let currentProcess = currentProcess {
      currentProcess.cancel()
    }
    self.currentProcess = provider.requestWithFilters(.listOption(chainId: chainId)) { result in
      switch result {
      case .success(let response):
        if let json = try? response.mapJSON() as? JSONDictionary ?? [:], let jsonResults = json["result"] as? [JSONDictionary] {
          
          var earnPools: [EarnPoolModel] = []
          jsonResults.forEach { jsonResult in
            earnPools.append(EarnPoolModel(json: jsonResult))
          }
          completion(earnPools)
        } else {
          completion([])
        }
      case .failure:
        completion([])
      }
    } as? Cancellable
  }
  
  func getStakingPortfolio(address: String, completion: @escaping (Result<([EarningBalance], [PendingUnstake]), AnyError>) -> Void) {
    let group = DispatchGroup()
    var eb: [EarningBalance]?
    var pu: [PendingUnstake]?
    
    var anyError: AnyError?
    
    group.enter()
    
    provider.requestWithFilters(.getEarningBalances(address: address)) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let decoded = try decoder.decode(EarningBalancesResponse.self, from: response.data)
          eb = decoded.earningBalances
        } catch let error {
          anyError = AnyError(error)
        }
      case .failure(let error):
        anyError = AnyError(error)
      }
      group.leave()
    }
    
    group.enter()
    provider.requestWithFilters(.getPendingUnstakes(address: address)) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let decoded = try decoder.decode(PendingUnstakesResponse.self, from: response.data)
          pu = decoded.pendingUnstakes
        } catch let error {
          anyError = AnyError(error)
        }
      case .failure(let error):
        anyError = AnyError(error)
      }
      group.leave()
    }
    
    group.notify(queue: .main) {
      let uw_eb = eb ?? []
      let uw_pu = pu ?? []
      completion(.success((uw_eb, uw_pu)))
    }
  }
  
}
