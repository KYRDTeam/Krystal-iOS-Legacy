//
//  KrystalApi.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import Moya

enum KrystalApi: TargetType {
  case transactions(address: String, prevHash: String?, limit: Int)
}

extension KrystalApi {
  
  var baseURL: URL {
    return URL(string: KNEnvironment.default.krytalAPIEndPoint)!
  }
  
  var path: String {
    switch self {
    case .transactions:
      return "/solana/v1/account/transactions"
    }
  }
  
  var method: Moya.Method {
    switch self {
    case .transactions:
      return .get
    }
  }
  
  var sampleData: Data { Data() }
  
  var task: Task {
    switch self {
    case .transactions(let address, let prevHash, let limit):
      var dict = [String: Any]()
      dict["address"] = address
      dict["beforeHash"] = prevHash
      dict["limit"] = limit
      return .requestParameters(parameters: dict, encoding: URLEncoding.default)
    }
  }
  
  var headers: [String : String]? {
    return nil
  }
  
}
