//
//  LidoParamBuilder.swift
//  EarnModule
//
//  Created by Tung Nguyen on 15/11/2022.
//

import Foundation
import Utilities
import Services

class LidoParamBuilder: EarnParamBuilder {
    
    func stakeExtraData(earningToken: EarningToken?) -> JSONDictionary {
        return [:]
    }
    
    func claimExtraData(pendingUnstake: PendingUnstake) -> JSONDictionary {
        return ["lido": ["nftTokenID": pendingUnstake.extraData.nftID]]
    }
    
}
