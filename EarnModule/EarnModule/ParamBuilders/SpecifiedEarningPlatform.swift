//
//  EarningPlatform.swift
//  EarnModule
//
//  Created by Tung Nguyen on 15/11/2022.
//

import Foundation

enum SpecifiedEarningPlatform: String {
    case ankr
    case lido
    case other
    
    init(name: String) {
        switch name {
        case "ankr":
            self = .ankr
        case "lido":
            self = .lido
        default:
            self = .other
        }
    }
}
