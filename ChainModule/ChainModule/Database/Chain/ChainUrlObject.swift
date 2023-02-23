//
//  ChainUrlObject.swift
//  ChainModule
//
//  Created by Tung Nguyen on 15/02/2023.
//

import Foundation
import RealmSwift

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
