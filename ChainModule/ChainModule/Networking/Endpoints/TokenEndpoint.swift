//
//  TokenEndpoint.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import Moya

enum TokenEndpoint {
    case getTokenList(chainPath: String)
    case getBalance(chainIDs: [Int], addresses: [String])
}

extension TokenEndpoint: TargetType {
    
    var baseURL: URL {
        return URL(string: "https://api-dev.krystal.team")!
    }
    
    var path: String {
        switch self {
        case .getTokenList(let chainPath):
            return "/\(chainPath)/v1/token/tokenList"
        case .getBalance:
            return "/all/v1/balance/token"
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
        case .getTokenList:
            return .requestPlain
        case .getBalance:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}
