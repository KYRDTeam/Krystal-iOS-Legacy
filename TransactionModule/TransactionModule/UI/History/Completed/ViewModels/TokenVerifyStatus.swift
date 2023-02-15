//
//  TokenVerifyStatus.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import UIKit

enum TokenVerifyStatus {
    case verified
    case promoted
    case unverified
    case scam
    case other
    
    init(value: String) {
        switch value {
        case "VERIFIED":
            self = .verified
        case "UNVERIFIED":
            self = .unverified
        case "PROMOTION":
            self = .promoted
        case "SCAM":
            self = .scam
        default:
            self = .other
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .verified:
            return .verifyToken
        case .promoted:
            return .promotedToken
        case .unverified:
            return nil
        case .scam:
            return .scamToken
        case .other:
            return nil
        }
    }
    
}
