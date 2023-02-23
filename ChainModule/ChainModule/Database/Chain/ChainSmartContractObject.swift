//
//  ChainSmartContractObject.swift
//  ChainModule
//
//  Created by Tung Nguyen on 15/02/2023.
//

import Foundation
import RealmSwift

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

