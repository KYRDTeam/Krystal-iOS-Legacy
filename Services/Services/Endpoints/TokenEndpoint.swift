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
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getTokenDetail, .getCommonBaseToken:
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
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}
