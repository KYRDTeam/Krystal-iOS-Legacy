//
//  TokenEntity.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import RealmSwift

class TokenEntity: Object {
    @Persisted var chainID: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var address: String = "" {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var iconUrl: String = ""
    @Persisted var decimal: Int = 18
    @Persisted var symbol: String = ""
    @Persisted var name: String = ""
    @Persisted var isAddedByUser: Bool = false {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var compoundKey: String = ""
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(chainID)-\(address)-\(isAddedByUser)"
    }
    
    override init() {
        super.init()
    }
    
    convenience init(chainID: Int, address: String, iconUrl: String, decimal: Int, symbol: String, name: String, isAddedByUser: Bool = false) {
        self.init()
        self.chainID = chainID
        self.address = address
        self.iconUrl = iconUrl
        self.decimal = decimal
        self.symbol = symbol
        self.name = name
        self.isAddedByUser = isAddedByUser
        self.compoundKey = compoundKeyValue()
    }

}
