//
//  Error+pretty.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Result
import APIKit
import JSONRPCKit

public extension Error {
    var prettyError: String {
        switch self {
        case let error as AnyError:
            switch error.error {
            case let error as APIKit.SessionTaskError:
                switch error {
                case .connectionError(let error):
                    return error.localizedDescription
                case .requestError(let error):
                    return error.localizedDescription
                case .responseError(let error):
                    guard let JSONError = error as? JSONRPCError else {
                        return error.localizedDescription
                    }
                    switch JSONError {
                    case .responseError(_, let message, _):
                        return message
                    case .responseNotFound(_, let object):
                        return (((object as? [String: Any])?["error"] as? [String: Any])?["message"] as? String) ?? "Undefined error"
                    default:
                        return "Undefined error"
                    }
                }
            default:
                return error.errorDescription ?? error.description
            }
        case let error as LocalizedError:
            return error.errorDescription ?? "An unknown error occurred."
        case let error as NSError:
            return error.localizedDescription
        default:
            return "Undefined Error"
        }
    }
    
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}
