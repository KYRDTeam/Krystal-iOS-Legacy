//
//  BalanceRequest.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import BigInt
import Foundation
import JSONRPCKit

struct BalanceRequest: JSONRPCKit.Request {
    typealias Response = BigInt

    let address: String

    var method: String {
        return "eth_getBalance"
    }

    var parameters: Any? {
        return [address, "latest"]
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? String, let value = BigInt(response.drop0x, radix: 16) {
            return value
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}
