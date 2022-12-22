//
//  HistoryEndpoint.swift
//  Services
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import Moya

enum HistoryEndpoint {
    case getHistory(walletAddress: String, tokenAddress: String?, chainIds: [Int], limit: Int, endTime: Int?)
}

extension HistoryEndpoint: TargetType {
    
    var baseURL: URL {
        return URL(string: ServiceConfig.baseAPIURL)!
    }
    
    var path: String {
        return "/all/v1/txHistory/getHistory"
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .getHistory(let walletAddress, let tokenAddress, let chainIds, let limit, let endTime):
            var params: [String: Any] = [:]
            params["walletAddress"] = walletAddress
            params["tokenAddress"] = tokenAddress
            params["chainIds"] = chainIds.map { "\($0)" }.joined(separator: ",")
            params["limit"] = limit
            params["endTime"] = endTime
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}
