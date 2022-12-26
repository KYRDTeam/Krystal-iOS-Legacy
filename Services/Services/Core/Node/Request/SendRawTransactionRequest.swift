// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import JSONRPCKit

public struct SendRawTransactionRequest: JSONRPCKit.Request {
    public typealias Response = String
    
    public let signedTransaction: String
    
    public init(signedTransaction: String) {
        self.signedTransaction = signedTransaction
    }
    
    public var method: String {
        return "eth_sendRawTransaction"
    }
    
    public var parameters: Any? {
        return [
            signedTransaction,
        ]
    }
    
    public func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}
