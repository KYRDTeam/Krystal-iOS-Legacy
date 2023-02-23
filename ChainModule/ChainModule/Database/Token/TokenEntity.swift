//
//  TokenEntity.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation
import RealmSwift

let nativeTokenType = "native"
let erc20TokenType = "erc20"

public class TokenEntity: Object {
    @Persisted public internal(set) var chainID: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted public internal(set) var address: String = "" {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted public internal(set) var iconUrl: String = ""
    @Persisted public internal(set) var decimal: Int = 18
    @Persisted public internal(set) var symbol: String = ""
    @Persisted public internal(set) var name: String = ""
    @Persisted public internal(set) var tag: String = ""
    @Persisted public internal(set) var type: String = "" // native / erc20
    @Persisted public internal(set) var isAddedByUser: Bool = false {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var compoundKey: String = ""
    @Persisted public internal(set) var isActive: Bool = true
    
    public override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(chainID)-\(address)-\(isAddedByUser)"
    }
    
    var isNativeToken: Bool {
        return type == nativeTokenType
    }
    
    override init() {
        super.init()
    }
    
    convenience init(chainID: Int, address: String, iconUrl: String, decimal: Int, symbol: String, name: String, tag: String, type: String, isAddedByUser: Bool = false, isActive: Bool = true) {
        self.init()
        self.chainID = chainID
        self.address = address
        self.iconUrl = iconUrl
        self.decimal = decimal
        self.symbol = symbol
        self.name = name
        self.tag = tag
        self.type = type
        self.isAddedByUser = isAddedByUser
        self.isActive = isActive
        self.compoundKey = compoundKeyValue()
    }

}
