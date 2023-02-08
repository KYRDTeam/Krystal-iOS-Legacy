//
//  TokenBalanceEntityConverter.swift
//  ChainModule
//
//  Created by Tung Nguyen on 07/02/2023.
//

import Foundation
import BigInt

class TokenBalanceEntityConverter: Converter {
    typealias Input = TokenBalanceEntity
    typealias Output = TokenBalance
    
    static func convert(input: TokenBalanceEntity) -> TokenBalance {
        return TokenBalance(chainID: input.chainID, tokenAddress: input.tokenAddress, walletAddress: input.walletAddress, balance: BigInt(input.balance) ?? .zero)
    }
}
