//
//  EarnParamBuilder.swift
//  EarnModule
//
//  Created by Tung Nguyen on 15/11/2022.
//

import Foundation
import Utilities
import Services
import AppState
import BigInt

protocol EarnParamBuilder {
    func stakeExtraData(earningToken: EarningToken?) -> JSONDictionary
    func claimExtraData(pendingUnstake: PendingUnstake) -> JSONDictionary
    func buildStakingTxParam(amount: BigInt, pool: EarnPoolModel, platform: EarnPlatform, earningToken: EarningToken?) -> JSONDictionary
    func buildClaimTxParam(pendingUnstake: PendingUnstake) -> JSONDictionary
}

extension EarnParamBuilder {
    
    func buildStakingTxParam(amount: BigInt, pool: EarnPoolModel, platform: EarnPlatform, earningToken: EarningToken?) -> JSONDictionary {
        var earningType = platform.type
        if pool.token.symbol.uppercased() == "MATIC" {
            earningType = "stakingMATIC"
        }
        let params: JSONDictionary = [
            "tokenAmount": amount.description,
            "chainID": pool.chainID,
            "earningType": earningType,
            "platform": platform.name,
            "userAddress": AppState.shared.currentAddress.addressString,
            "tokenAddress": pool.token.address,
            "extraData": stakeExtraData(earningToken: earningToken)
        ]
        return params
    }
    
    func buildClaimTxParam(pendingUnstake: PendingUnstake) -> JSONDictionary {
        let params: JSONDictionary = [
            "tokenAmount": pendingUnstake.balance,
            "chainID": pendingUnstake.chainID,
            "earningType": pendingUnstake.platform.type,
            "platform": pendingUnstake.platform.name,
            "userAddress": AppState.shared.currentAddress.addressString,
            "tokenAddress": pendingUnstake.address,
            "extraData": claimExtraData
        ]
        return params
    }
    
}
