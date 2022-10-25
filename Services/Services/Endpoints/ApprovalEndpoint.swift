//
//  ApprovalEndpoint.swift
//  Services
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation
import Moya

enum ApprovalEndpoint {
    case list(address: String, chainIds: [Int])
}

extension ApprovalEndpoint: TargetType {
    
    var baseURL: URL {
        return URL(string: ServiceConfig.baseAPIURL)!
    }
    
    var path: String {
        switch self {
        case .list:
            return "/all/v1/approval/list"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .list:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .list(let address, let chainIds):
            let params = [
                "address": address,
                "chainIds": chainIds.map(String.init).joined(separator: ",")
            ]
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}

