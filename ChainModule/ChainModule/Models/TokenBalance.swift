//
//  TokenBalance.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import BigInt

public class TokenBalance {
    public var chainID: Int = 0
    public var tokenAddress: String = ""
    public var walletAddress: String = ""
    public var balance: BigInt = .zero
    
    public init(chainID: Int = 0, tokenAddress: String = "", walletAddress: String = "", balance: BigInt = .zero) {
        self.chainID = chainID
        self.tokenAddress = tokenAddress
        self.walletAddress = walletAddress
        self.balance = balance
    }
    
}
