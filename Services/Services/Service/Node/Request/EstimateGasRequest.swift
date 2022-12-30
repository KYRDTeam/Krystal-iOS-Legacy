// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import JSONRPCKit
import BigInt
import Utilities

struct EstimateGasRequest: JSONRPCKit.Request {
    typealias Response = String
    
    let from: String
    let to: String?
    let value: BigInt
    let data: Data
    
    var method: String {
        return "eth_estimateGas"
    }
    
    var parameters: Any? {
        return [
            [
                "from": from,
                "to": to ?? "",
                // Mike: Temp fix for estimate gas, no value needed
                //                "value": value.description.hexEncoded,
                "data": data.hexEncoded,
            ],
        ]
    }
    
    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}
