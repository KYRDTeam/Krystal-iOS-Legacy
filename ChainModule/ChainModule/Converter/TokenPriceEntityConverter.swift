//
//  TokenPriceEntityConverter.swift
//  ChainModule
//
//  Created by Tung Nguyen on 17/02/2023.
//

import Foundation

class TokenPriceEntityConverter: Converter {
    typealias Input = TokenPriceEntity
    typealias Output = TokenPrice
    
    static func convert(input: TokenPriceEntity) -> TokenPrice {
        return TokenPrice(chainID: input.chainID, tokenAddress: input.tokenAddress, price: input.price)
    }

}
