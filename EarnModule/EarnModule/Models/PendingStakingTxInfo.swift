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
    var pool: EarnPoolModel
    var platform: EarnPlatform
    var selectedDestToken: EarningToken
    var sourceAmount: String
    var destAmount: String
    
    init(pool: EarnPoolModel, platform: EarnPlatform, selectedDestToken: EarningToken, sourceAmount: String, destAmount: String, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: BaseWallet.ChainType, date: Date, hash: String, nonce: Int) {
        self.platform = platform
        self.pool = pool
        self.selectedDestToken = selectedDestToken
        self.sourceAmount = sourceAmount
        self.destAmount = destAmount
        super.init(type: .earn, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash, nonce: nonce)
    }
    
    override var destSymbol: String? {
        return selectedDestToken.symbol
    }
     
    override var sourceSymbol: String? {
        return pool.token.symbol
    }
    
    override var sourceIcon: String? {
        return pool.token.logo
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

    override var amount: String? {
        return platform.name.uppercased()
    }
}
