//
//  TxErrorParser.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import Result
import APIKit
import JSONRPCKit

public enum TxError: Error {
    case insuffienceBalance
    case unknown
    case unexpected(message: String)
    case undefined
    
    public var message: String {
        switch self {
        case .insuffienceBalance:
            return "Transaction will probably fail. There may be low liquidity, you can try a smaller amount or increase the slippage."
        case .unknown:
            return "Transaction will probably fail due to various reasons. Please try increasing the slippage or selecting a different platform."
        case .unexpected(let message):
            return message
        case .undefined:
            return "Something went wrong, please try again"
        }
    }
}

public class TxErrorParser {
    
    public static func parse(error: AnyError) -> TxError {
        var errorMessage = ""
        if case let APIKit.SessionTaskError.responseError(apiKitError) = error.error {
          if case let JSONRPCKit.JSONRPCError.responseError(_, message, _) = apiKitError {
              errorMessage = message
          }
        }
        if errorMessage.lowercased().contains("INSUFFICIENT_OUTPUT_AMOUNT".lowercased()) || errorMessage.lowercased().contains("Return amount is not enough".lowercased()) {
            return .insuffienceBalance
        }
        if errorMessage.lowercased().contains("Unknown(0x)".lowercased()) {
            return .unknown
        }
        if errorMessage.isEmpty {
            return .undefined
        } else {
            return .unexpected(message: errorMessage)
        }
    }
    
}

