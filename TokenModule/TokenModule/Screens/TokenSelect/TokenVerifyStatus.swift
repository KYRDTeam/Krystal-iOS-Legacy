//
//  TokenVerifyStatus.swift
//  TokenModule
//
//  Created by Tung Nguyen on 23/12/2022.
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
            return Images.verifyToken
        case .promoted:
            return Images.promotedToken
        case .unverified:
            return Images.unverifiedToken
        case .scam:
            return nil
        case .other:
            return nil
        }
    }
    
}
