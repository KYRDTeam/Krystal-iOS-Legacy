//
//  EarningType.swift
//  EarnModule
//
//  Created by Tung Nguyen on 21/11/2022.
//

import Foundation

enum EarningType: String {
    case staking
    case lending
    
    init(value: String) {
        switch value.lowercased() {
        case "stake", "staking":
            self = .staking
        case "lend", "lending":
            self = .lending
        default:
            self = .lending
        }
    }
}
