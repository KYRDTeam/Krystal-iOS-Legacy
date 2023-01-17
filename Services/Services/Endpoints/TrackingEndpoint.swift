//
//  TrackingEndpoint.swift
//  Services
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation
import Moya
import Utilities

enum TrackingEndpoint {
    case sendRate(star: Int, detail: String, txHash: String)
}

extension TrackingEndpoint: TargetType {
    
    var baseURL: URL {
        return URL(string: ServiceConfig.baseAPIURL)!
    }
    
    var path: String {
        switch self {
        case .sendRate:
            return "/all/v1/tracking/ratings"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .sendRate:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .sendRate(let star, let detail, let txHash):
            let json: JSONDictionary = [
              "category": "swap",
              "detail": detail,
              "star": star,
              "txHash": txHash
            ]
            return .requestParameters(parameters: json, encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}

