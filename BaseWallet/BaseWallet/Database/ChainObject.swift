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
    
    convenience init(chainID: Int, name: String, iconUrl: String, isDefault: Bool) {
        self.init()
        self.id = chainID
        self.name = name
        self.iconUrl = iconUrl
        self.isDefault = isDefault
        self.compoundKey = compoundKeyValue()
    }
}

final class ChainSmartContractObject: Object {
    @Persisted var chainID: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var address: String = ""
    @Persisted var type: String = "" {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var compoundKey: String = ""
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(chainID)-\(type)"
    }
    
    override init() {
        super.init()
    }
    
    convenience init(chainID: Int, address: String, type: String) {
        self.init()
        self.chainID = chainID
        self.address = address
        self.type = type
        self.compoundKey = compoundKeyValue()
    }
}

final class ChainUrlObject: Object {
    @Persisted var chainID: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var url: String = ""
    @Persisted var type: String = "" {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var priority: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var compoundKey: String = ""
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(chainID)-\(priority)-\(type)"
    }
    
    override init() {
        super.init()
    }
    
    convenience init(chainID: Int, url: String, type: String) {
        self.init()
        self.chainID = chainID
        self.url = url
        self.type = type
        self.compoundKey = compoundKeyValue()
    }
}

final class ChainConfigObject: Object {
    @Persisted var chainID: Int = 0 {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var name: String = "" {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    @Persisted var value: String = ""
    @Persisted var compoundKey: String = ""
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(chainID)-\(name)"
    }
    
    override init() {
        super.init()
    }
    
    convenience init(chainID: Int, name: String, value: String) {
        self.init()
        self.chainID = chainID
        self.name = name
        self.value = value
        self.compoundKey = compoundKeyValue()
    }
}

