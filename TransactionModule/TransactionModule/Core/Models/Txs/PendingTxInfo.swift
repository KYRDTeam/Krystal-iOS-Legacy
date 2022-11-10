//
//  TxInfo.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 10/11/2022.
//

import Foundation
import BaseWallet

public enum TxType {
    case earn
    case approval
}

public struct PendingTxInfo {
    public var type: TxType
    public var fromSymbol: String
    public var toSymbol: String
    public var description: String
    public var detail: String
    public var legacyTx: LegacyTransaction?
    public var eip1559Tx: EIP1559Transaction?
    public var chain: ChainType
    public var date: Date
    public var hash: String
    public var nonce: Int
    
    public init(type: TxType, fromSymbol: String, toSymbol: String, description: String, detail: String, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: ChainType, date: Date, hash: String, nonce: Int) {
        self.type = type
        self.fromSymbol = fromSymbol
        self.toSymbol = toSymbol
        self.description = description
        self.detail = detail
        self.legacyTx = legacyTx
        self.eip1559Tx = eip1559Tx
        self.chain = chain
        self.date = date
        self.hash = hash
        self.nonce = nonce
    }
}
