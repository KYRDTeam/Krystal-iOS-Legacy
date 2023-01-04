//
//  SwapEndpoint.swift
//  Services
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import Moya
import Utilities


enum SwapEndpoint {
    case getExpectedRate(chainPath: String, src: String, dst: String, srcAmount: String, hint: String, isCaching: Bool)
    case getAllRates(chainPath: String, src: String, dst: String, amount: String, focusSrc: Bool, userAddress: String)
    case buildSwapTx(chainPath: String, address: String, src: String, dst: String, srcAmount: String, minDstAmount: String, gasPrice: String, nonce: Int, hint: String, useGasToken: Bool)
}

extension SwapEndpoint: TargetType {
    
    var baseURL: URL {
        return URL(string: ServiceConfig.baseAPIURL)!
    }
    
    var path: String {
        switch self {
        case .getExpectedRate(let chainPath, _, _, _, _, _):
            return "/\(chainPath)/v2/swap/expectedRate"
        case .getAllRates(let chainPath, _, _, _, _, _):
            return "/\(chainPath)/v2/swap/allRates"
        case .buildSwapTx(let chainPath, _, _, _, _, _, _, _, _, _):
            return "/\(chainPath)/v2/swap/buildTx"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getExpectedRate:
            return .get
        case .getAllRates:
            return .get
        case .buildSwapTx:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .getExpectedRate(_, let src, let dst, let srcAmount, let hint, let isCaching):
            let json: [String: Any] = [
                "src": src,
                "dest": dst,
                "srcAmount": srcAmount,
                "hint": hint,
                "isCaching": isCaching,
            ]
            return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
        case .getAllRates(_, let src, let dst, let amount, let focusSrc, let userAddress):
            var json: [String: Any] = [
                "src": src,
                "dest": dst,
                "platformWallet": ServiceConfig.platformWallet!
            ]
            
            if !userAddress.isEmpty {
                json["userAddress"] = userAddress
            }
            
            if focusSrc {
                json["srcAmount"] = amount
            } else {
                json["destAmount"] = amount
            }
            return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
        case .buildSwapTx(_, let address, let src, let dst, let srcAmount, let minDstAmount, let gasPrice, let nonce, let hint, let useGasToken):
            let json: [String: Any] = [
                "userAddress": address,
                "src": src,
                "dest": dst,
                "srcAmount": srcAmount,
                "minDestAmount": minDstAmount,
                "gasPrice": gasPrice,
                "nonce": nonce,
                "hint": hint,
                "platformWallet": ServiceConfig.platformWallet!,
                "useGasToken": useGasToken,
            ]
            return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        return [:]
    }
    
}
