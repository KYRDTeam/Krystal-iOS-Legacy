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
    public var isAddedByUser: Bool = false
    
    init(chainID: Int, address: String, iconUrl: String, decimal: Int, symbol: String, name: String, isAddedByUser: Bool) {
        self.chainID = chainID
        self.address = address
        self.iconUrl = iconUrl
        self.decimal = decimal
        self.symbol = symbol
        self.name = name
        self.isAddedByUser = isAddedByUser
    }
}
