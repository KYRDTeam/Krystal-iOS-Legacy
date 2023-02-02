//
//  TokenEntityConverter.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

class TokenEntityConverter: Converter {
    typealias Input = TokenEntity
    typealias Output = Token
    
    static func convert(input: TokenEntity) -> Token {
        return Token(chainID: input.chainID, address: input.address, iconUrl: input.iconUrl, decimal: input.decimal, symbol: input.symbol, name: input.name, isAddedByUser: input.isAddedByUser)
    }
}
