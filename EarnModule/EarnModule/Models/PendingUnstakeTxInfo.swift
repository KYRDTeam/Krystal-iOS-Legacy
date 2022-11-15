//
//  PendingUnstakeTxInfo.swift
//  EarnModule
//
//  Created by Com1 on 15/11/2022.
//

import Foundation
import TransactionModule
import Services
import BaseWallet

class PendingUnstakeTxInfo: PendingTxInfo {
    var platform: Platform
    
    var stakingTokenAmount: String
    var toTokenAmount: String
    
    var stakingTokenSymbol: String
    var toTokenSymbol: String
    
    var stakingTokenLogo: String
    var toTokenLogo: String
    
    
    init(platform: Platform, stakingTokenAmount: String, toTokenAmount: String, stakingTokenSymbol: String, toTokenSymbol: String, stakingTokenLogo: String, toTokenLogo: String, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: BaseWallet.ChainType, date: Date, hash: String, nonce: Int) {
        self.platform = platform
        self.stakingTokenAmount = stakingTokenAmount
        self.toTokenAmount = toTokenAmount
        self.stakingTokenSymbol = stakingTokenSymbol
        self.toTokenSymbol = toTokenSymbol
        self.stakingTokenLogo = stakingTokenLogo
        self.toTokenLogo = toTokenLogo
        super.init(type: .unstake, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash, nonce: nonce)
    }

    override var destSymbol: String? {
        return toTokenSymbol
    }
     
    override var sourceSymbol: String? {
        return stakingTokenSymbol
    }
    
    override var sourceIcon: String? {
        return stakingTokenLogo
    }
    
    override var destIcon: String? {
        return toTokenLogo
    }
    
    override var description: String {
        return "\(stakingTokenAmount) \(stakingTokenSymbol) → \(toTokenAmount) \(toTokenSymbol)"
    }
 
    override var detail: String {
        return ""
    }
    
    override var amount: String? {
        return platform.name.uppercased()
    }
}
