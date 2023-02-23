//
//  TokenPrice.swift
//  ChainModule
//
//  Created by Tung Nguyen on 17/02/2023.
//

import Foundation

public class TokenPrice {
    public var chainID: Int = 0
    public var tokenAddress: String = ""
    public var price: Double = 0
    
    public init(chainID: Int = 0, tokenAddress: String = "", price: Double = 0) {
        self.chainID = chainID
        self.tokenAddress = tokenAddress
        self.price = price
    }
    
}
