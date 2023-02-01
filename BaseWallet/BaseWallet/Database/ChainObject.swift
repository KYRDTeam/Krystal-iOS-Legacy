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
    @Persisted var nativeTokenSymbol: String = ""
    @Persisted var isActive: Bool = false
    @Persisted var isDefault: Bool = false
    @Persisted var isAddedByUser: Bool = false {
        didSet {
            compoundKey = compoundKeyValue()
        }
    }
    dynamic lazy var compoundKey: String = compoundKeyValue()
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(id)-\(isAddedByUser)"
    }
}

final class ChainSmartContractObject: Object {
    @Persisted var chainID: Int = 0
    @Persisted var address: String = ""
    @Persisted var type: String = ""
}

final class ChainUrlObject: Object {
    @Persisted var chainID: Int = 0
    @Persisted var url: String = ""
    @Persisted var type: String = ""
}

final class ChainConfigObject: Object {
    @Persisted var chainID: Int = 0
    @Persisted var name: String = ""
    @Persisted var value: String = ""
}

