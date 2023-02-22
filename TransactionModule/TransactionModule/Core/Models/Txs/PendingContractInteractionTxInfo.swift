//
//  PendingContractInteractionTxInfo.swift
//  TransactionModule
//
//  Created by Com1 on 20/02/2023.
//

import Foundation
import BaseWallet

public class PendingContractInteractionTxInfo: PendingTxInfo {
    public init(legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: ChainType, date: Date, hash: String) {
        super.init(type: .contractInteraction, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash)
    }
    
    public override var description: String {
        return "Dapp-description"
    }
    
    public override var detail: String {
        return "Dapp - detail"
    }
    
    public override var sourceSymbol: String? {
        return "Dapp - source"
    }
    
    public override var destSymbol: String? {
        return "Dapp -dest"
    }
}
