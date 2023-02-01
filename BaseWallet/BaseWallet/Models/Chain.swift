//
//  Chain.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

public class Chain {
    public var id: Int
    public var name: String
    public var iconUrl: String
    public var isActive: Bool
    public var isDefault: Bool
    public var isAddedByUser: Bool
    public var smartContracts: [ChainSmartContract] = []
    public var urls: [ChainUrl] = []
    public var configs: [ChainConfig] = []
    
    public init(id: Int, name: String, iconUrl: String, isActive: Bool, isDefault: Bool, isAddedByUser: Bool, smartContracts: [ChainSmartContract] = [], urls: [ChainUrl] = [], configs: [ChainConfig] = []) {
        self.id = id
        self.name = name
        self.iconUrl = iconUrl
        self.isActive = isActive
        self.isDefault = isDefault
        self.isAddedByUser = isAddedByUser
        self.smartContracts = smartContracts
        self.urls = urls
        self.configs = configs
    }
}

public class ChainSmartContract {
    public var chainID: Int
    public var address: String
    public var type: String
    
    public init(chainID: Int, address: String, type: String) {
        self.chainID = chainID
        self.address = address
        self.type = type
    }
}

public class ChainUrl {
    public var chainID: Int
    public var url: String
    public var type: String
    
    public init(chainID: Int, url: String, type: String) {
        self.chainID = chainID
        self.url = url
        self.type = type
    }
}

public class ChainConfig {
    public var chainID: Int
    public var name: String
    public var value: String
    
    public init(chainID: Int, name: String, value: String) {
        self.chainID = chainID
        self.name = name
        self.value = value
    }
    
}

