//
//  TxInfo.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 10/11/2022.
//

import Foundation
import BaseWallet
import Services

public enum TxType {
    case earn
    case approval
    case unstake
}

open class PendingTxInfo {
    public var type: TxType
    public var legacyTx: LegacyTransaction?
    public var eip1559Tx: EIP1559Transaction?
    public var chain: ChainType
    public var date: Date
    public var hash: String
    public var nonce: Int
    
    public init(type: TxType, legacyTx: LegacyTransaction? = nil, eip1559Tx: EIP1559Transaction? = nil, chain: ChainType, date: Date, hash: String, nonce: Int) {
        self.type = type
        self.legacyTx = legacyTx
        self.eip1559Tx = eip1559Tx
        self.chain = chain
        self.date = date
        self.hash = hash
        self.nonce = nonce
    }
    
    open var description: String {
        fatalError("Must override this property")
    }
    
    open var detail: String {
        fatalError("Must override this property")
    }
    
    open var sourceSymbol: String? {
        fatalError("Must override this property")
    }
    
    open var destSymbol: String? {
        fatalError("Must override this property")
    }
    
    open var sourceIcon: String? {
        fatalError("Must override this property")
    }
    
    open var destIcon: String? {
        fatalError("Must override this property")
    }
    
    open var amount: String? {
        fatalError("Must override this property")
    }
}
