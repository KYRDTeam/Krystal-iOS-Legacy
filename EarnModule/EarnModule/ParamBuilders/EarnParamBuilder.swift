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
    func buildStakingTxParam(amount: BigInt, token: Token, chainID: Int, platform: EarnPlatform, earningToken: EarningToken?) -> JSONDictionary
    func buildClaimTxParam(pendingUnstake: PendingUnstake) -> JSONDictionary
}

extension EarnParamBuilder {
    
    func buildStakingTxParam(amount: BigInt, token: Token, chainID: Int, platform: EarnPlatform, earningToken: EarningToken?) -> JSONDictionary {
        var earningType = platform.type
        if token.symbol.uppercased() == "MATIC" {
            earningType = "stakingMATIC"
        }
        let params: JSONDictionary = [
            "tokenAmount": amount.description,
            "chainID": chainID,
            "earningType": earningType,
            "platform": platform.name,
            "userAddress": AppState.shared.currentAddress.addressString,
            "tokenAddress": token.address,
            "extraData": stakeExtraData(earningToken: earningToken)
        ]
        return params
    }
    
    func buildClaimTxParam(pendingUnstake: PendingUnstake) -> JSONDictionary {
        var earningType = pendingUnstake.platform.type
        if pendingUnstake.symbol.uppercased() == "MATIC" {
            earningType = "stakingMATIC"
        }
        let params: JSONDictionary = [
            "tokenAmount": pendingUnstake.balance,
            "chainID": pendingUnstake.chainID,
            "earningType": earningType,
            "platform": pendingUnstake.platform.name,
            "userAddress": AppState.shared.currentAddress.addressString,
            "tokenAddress": pendingUnstake.address,
            "extraData": claimExtraData(pendingUnstake: pendingUnstake)
        ]
        return params
    }
    
}
