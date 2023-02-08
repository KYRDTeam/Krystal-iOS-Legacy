//
//  TokenBalanceEntity.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import RealmSwift

class TokenBalanceEntity: Object {
    @Persisted var chainID: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var tokenAddress: String = "" {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var walletAddress: String = "" {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var balance: String = ""
    @Persisted var compoundKey: String = ""
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(chainID)-\(tokenAddress)-\(walletAddress)"
    }
    
    override init() {
        super.init()
    }
    
    convenience init(chainID: Int, tokenAddress: String, walletAddress: String, balance: String) {
        self.init()
        self.chainID = chainID
        self.tokenAddress = tokenAddress
        self.walletAddress = walletAddress
        self.balance = balance
        self.compoundKey = compoundKeyValue()
    }
}
