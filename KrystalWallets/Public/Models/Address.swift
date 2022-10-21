//
//  Address.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation

public struct KAddress {
    public var id: String
    public var walletID: String
    public var addressType: KAddressType
    public var name: String
    public var addressString: String
    
    public init(id: String, walletID: String, addressType: KAddressType, name: String, addressString: String) {
        self.id = id
        self.walletID = walletID
        self.addressType = addressType
        self.name = name
        self.addressString = addressString
    }
    
    public var isWatchWallet: Bool {
        return walletID.isEmpty
    }
}
