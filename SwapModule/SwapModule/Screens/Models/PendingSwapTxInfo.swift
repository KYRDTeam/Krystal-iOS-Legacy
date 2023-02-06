//
//  PendingSwapTxInfo.swift
//  SwapModule
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation
import TransactionModule
import Services
import BaseWallet

class PendingSwapTxInfo: PendingTxInfo {
    var sourceToken: Token
    var destToken: Token
    var rate: Rate
    var sourceAmount: String
    var destAmount: String
    var detailString: String
    
    init(sourceToken: Token, destToken: Token, rate: Rate, sourceAmount: String, destAmount: String, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: ChainType, date: Date, hash: String, detailString: String) {
        self.sourceToken = sourceToken
        self.destToken = destToken
        self.rate = rate
        self.sourceAmount = sourceAmount
        self.destAmount = destAmount
        self.detailString = detailString
        super.init(type: .swap, legacyTx: legacyTx, eip1559Tx: eip1559Tx, chain: chain, date: date, hash: hash)
    }
    
    override var destSymbol: String? {
        return destToken.symbol
    }
     
    override var sourceSymbol: String? {
        return sourceToken.symbol
    }
    
    override var sourceIcon: String? {
        return sourceToken.logo
    }
    
    override var destIcon: String? {
        return destToken.logo
    }
    
    override var description: String {
        return "\(sourceAmount) → \(destAmount)"
    }
        
    override var detail: String {
        return detailString
    }
}
