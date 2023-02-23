//
//  TokenPriceObject.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import RealmSwift

class TokenPriceEntity: Object {
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
    @Persisted var price: Double = 0
    @Persisted var compoundKey: String = ""
    
    public override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(chainID)-\(tokenAddress)"
    }
    
    public override init() {
        super.init()
    }
    
    public convenience init(chainID: Int, tokenAddress: String, price: Double) {
        self.init()
        self.chainID = chainID
        self.tokenAddress = tokenAddress
        self.price = price
        self.compoundKey = compoundKeyValue()
    }
}
