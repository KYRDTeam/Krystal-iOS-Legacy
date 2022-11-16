//
//  PendingConfirmTxInfo.swift
//  EarnModule
//
//  Created by Tung Nguyen on 16/11/2022.
//

import Foundation
import Services
import TransactionModule
import BaseWallet

class PendingClaimTxInfo: PendingTxInfo {
    
    let pendingUnstake: PendingUnstake
    
    init(pendingUnstake: PendingUnstake, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: ChainType, date: Date, hash: String) {
        self.pendingUnstake = pendingUnstake
        super.init(type: .claimStakingReward, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash)
    }
    
    override var description: String {
        return ""
    }
    
    override var detail: String {
        return ""
    }
    
    override var sourceSymbol: String? {
        return ""
    }
    
    override var destSymbol: String? {
        return ""
    }
    
    override var sourceIcon: String? {
        return ""
    }
    
    override var destIcon: String? {
        return ""
    }
    
}
