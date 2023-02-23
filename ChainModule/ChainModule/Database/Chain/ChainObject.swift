//
//  Chain.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 30/01/2023.
//

import Foundation
import RealmSwift

final class ChainObject: Object {
    @Persisted var id: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var type: String = "EVM"
    @Persisted var name: String = ""
    @Persisted var iconUrl: String = ""
    @Persisted var isActive: Bool = false
    @Persisted var isDefault: Bool = false
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
        return "\(id)-\(isAddedByUser)"
    }
    
    override init() {
        super.init()
    }
    
    convenience init(chainID: Int, name: String, type: String = "EVM", iconUrl: String, isDefault: Bool) {
        self.init()
        self.id = chainID
        self.name = name
        self.type = type
        self.iconUrl = iconUrl
        self.isDefault = isDefault
        self.compoundKey = compoundKeyValue()
    }
}
