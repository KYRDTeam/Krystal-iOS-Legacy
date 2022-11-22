//
//  AnkrParamBuilder.swift
//  EarnModule
//
//  Created by Tung Nguyen on 15/11/2022.
//

import Foundation
import Services
import Utilities

class AnkrParamBuilder: EarnParamBuilder {
    
    func stakeExtraData(earningToken: EarningToken?) -> JSONDictionary {
        var useTokenC = false
        if earningToken?.symbol.last?.lowercased() == "c" {
            useTokenC = true
        }
        return ["ankr": ["useTokenC": useTokenC]]
    }
    
    func claimExtraData(pendingUnstake: PendingUnstake) -> JSONDictionary {
        return [:]
    }
    
}
