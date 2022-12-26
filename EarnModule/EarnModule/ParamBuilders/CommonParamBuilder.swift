//
//  CommonParamBuilder.swift
//  EarnModule
//
//  Created by Tung Nguyen on 15/11/2022.
//

import Foundation
import Utilities
import Services

class CommonParamBuilder: EarnParamBuilder {
    
    func stakeExtraData(earningToken: EarningToken?) -> JSONDictionary {
        return [:]
    }
    
    func claimExtraData(pendingUnstake: PendingUnstake) -> JSONDictionary {
        return [:]
    }
    
}
