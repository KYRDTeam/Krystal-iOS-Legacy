//
//  PendingStakingTxInfo.swift
//  EarnModule
//
//  Created by Tung Nguyen on 11/11/2022.
//

import Foundation
import TransactionModule
import Services
import BaseWallet

class PendingStakingTxInfo: PendingTxInfo {
    var token: Token
    var platform: EarnPlatform
    var selectedDestToken: EarningToken
    var sourceAmount: String
    var destAmount: String
    let earningType: EarningType
    
    init(token: Token, platform: EarnPlatform, selectedDestToken: EarningToken, sourceAmount: String, destAmount: String, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: BaseWallet.ChainType, date: Date, hash: String, earningType: EarningType, trackingExtraData: StakingTrackingExtraData) {
        self.platform = platform
        self.token = token
        self.selectedDestToken = selectedDestToken
        self.sourceAmount = sourceAmount
        self.destAmount = destAmount
        self.earningType = earningType
        super.init(type: .earn, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash, trackingExtraData: trackingExtraData)
    }
    
    override var destSymbol: String? {
        return selectedDestToken.symbol
    }
     
    override var sourceSymbol: String? {
        return token.symbol
    }
    
    override var sourceIcon: String? {
        return token.logo
    }
    
    override var destIcon: String? {
        return selectedDestToken.logo
    }
    
    override var description: String {
        return "\(sourceAmount) → \(destAmount)"
    }
        
    override var detail: String {
        return ""
    }
}
