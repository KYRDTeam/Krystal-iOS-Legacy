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

public class PendingStakingTxInfo: PendingTxInfo {
    var pool: EarnPoolModel
    var platform: EarnPlatform
    var selectedDestToken: EarningToken
    var sourceAmount: String
    var destAmount: String
    
    public init(pool: EarnPoolModel, platform: EarnPlatform, selectedDestToken: EarningToken, sourceAmount: String, destAmount: String, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: BaseWallet.ChainType, date: Date, hash: String, nonce: Int) {
        self.platform = platform
        self.pool = pool
        self.selectedDestToken = selectedDestToken
        self.sourceAmount = sourceAmount
        self.destAmount = destAmount
        super.init(type: .earn, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash, nonce: nonce)
    }
    
    override public var destSymbol: String? {
        return selectedDestToken.symbol
    }
     
    override public var sourceSymbol: String? {
        return pool.token.symbol
    }
    
    override public var sourceIcon: String? {
        return pool.token.logo
    }
    
    override public var destIcon: String? {
        return selectedDestToken.logo
    }
    
    override public var description: String {
        return "\(sourceAmount) \(pool.token.symbol) → \(destAmount) \(pool.token.symbol)"
    }
        
    override public var detail: String {
        return ""
    }

}
