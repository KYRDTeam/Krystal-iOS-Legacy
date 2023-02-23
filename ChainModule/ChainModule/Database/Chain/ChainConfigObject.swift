//
//  ChainConfigObject.swift
//  ChainModule
//
//  Created by Tung Nguyen on 15/02/2023.
//

import Foundation
import RealmSwift

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

