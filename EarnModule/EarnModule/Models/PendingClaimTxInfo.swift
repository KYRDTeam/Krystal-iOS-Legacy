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
import Utilities
import BigInt

class PendingClaimTxInfo: PendingTxInfo {
    
    let pendingUnstake: PendingUnstake
    
    init(pendingUnstake: PendingUnstake, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: ChainType, date: Date, hash: String) {
        self.pendingUnstake = pendingUnstake
        super.init(type: .claimStakingReward, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash)
    }
    
    override var description: String {
        let amount = BigInt(pendingUnstake.balance) ?? .zero
        return "+" + NumberFormatUtils.amount(value: amount, decimals: pendingUnstake.decimals) + " " + pendingUnstake.symbol
    }
    
    override var detail: String {
        return "From: " + pendingUnstake.platform.name
    }
    
    override var sourceSymbol: String? {
        return nil
    }
    
    override var destSymbol: String? {
        return nil
    }
    
    override var sourceIcon: String? {
        return nil
    }
    
    override var destIcon: String? {
        return nil
    }
    
}
