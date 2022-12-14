// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import JSONRPCKit
import BigInt
import Utilities

public struct KNEstimateGasLimitRequest: JSONRPCKit.Request {
    public typealias Response = String
    
    public let from: String
    public let to: String?
    public let value: BigInt
    public let data: Data
    public let gasPrice: BigInt
    
    public var method: String {
        return "eth_estimateGas"
    }
    
    public var parameters: Any? {
        return [
            [
                "from": from.lowercased(),
                "to": to?.lowercased() ?? "0x",
                "gasPrice": gasPrice.hexEncoded,
                "value": value.hexEncoded,
                "data": data.hexEncoded,
            ],
        ]
    }
    
    public func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
    
    public init(from: String, to: String?, value: BigInt, data: Data, gasPrice: BigInt) {
        self.from = from
        self.to = to
        self.value = value
        self.data = data
        self.gasPrice = gasPrice
    }
}
