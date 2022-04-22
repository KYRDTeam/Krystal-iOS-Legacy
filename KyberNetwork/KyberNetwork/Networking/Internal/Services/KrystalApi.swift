//
//  KrystalApi.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import Moya

enum KrystalApi: TargetType {
  case transactions(address: String)
}

extension KrystalApi {
  
  var baseURL: URL {
    return URL(string: "https://api-dev.krystal.team")!
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
    case .transactions(let address):
      return .requestParameters(parameters: ["address": address], encoding: URLEncoding.default)
    }
  }
  
  var headers: [String : String]? {
    return nil
  }
  
}
