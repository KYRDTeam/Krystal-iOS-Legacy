//
//  Token.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

public class Token {
    public var chainID: Int = 0
    public var address: String = ""
    public var iconUrl: String = ""
    public var decimal: Int = 18
    public var symbol: String = ""
    public var name: String = ""
    public var tag: String = ""
    public var type: String = "" // native / erc20
    public var isAddedByUser: Bool = false
    
    public init(chainID: Int, address: String, iconUrl: String, decimal: Int, symbol: String, name: String, tag: String, type: String, isAddedByUser: Bool) {
        self.chainID = chainID
        self.address = address
        self.iconUrl = iconUrl
        self.decimal = decimal
        self.symbol = symbol
        self.name = name
        self.tag = tag
        self.type = type
        self.isAddedByUser = isAddedByUser
    }
    
    public var isNativeToken: Bool {
        return type == "native"
    }
}
