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
        self = .init(rawValue: value) ?? .lending
    }
}
