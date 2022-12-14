//
//  GasEndpoint.swift
//  Services
//
//  Created by Tung Nguyen on 01/11/2022.
//

import Foundation
import Moya

enum GasEndpoint {
    case getGasPrice(chainPath: String)
}

extension GasEndpoint: TargetType {
    
    var baseURL: URL {
        return URL(string: ServiceConfig.baseAPIURL)!
    }
    
    var path: String {
        switch self {
        case .getGasPrice(let chainPath):
            return "/\(chainPath)/v2/gasPrice"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getGasPrice:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .getGasPrice:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}

