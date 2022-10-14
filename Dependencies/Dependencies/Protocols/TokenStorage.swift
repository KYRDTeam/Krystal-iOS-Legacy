//
//  TokenStorage.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BaseWallet

public protocol TokenStorage {
    func getAllSupportedTokens() -> [Token]
}

public extension TokenStorage {
    
    func quoteToken(forChain chain: ChainType) -> Token {
        return Dependencies.tokenStorage.getAllSupportedTokens().first { token in
            return token.symbol == chain.customRPC().quoteToken && token.address == chain.customRPC().quoteTokenAddress
        } ?? Token(name: chain.customRPC().quoteToken,
                   symbol: chain.customRPC().quoteToken,
                   address: chain.customRPC().quoteTokenAddress,
                   decimals: 18,
                   logo: chain.customRPC().quoteToken.lowercased())
    }
    
}
