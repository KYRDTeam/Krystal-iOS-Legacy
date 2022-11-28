//
//  TokenStorage.swift
//  Dependencies
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import BaseWallet
import Services

public protocol TokenStorage {
    func getAllSupportedTokens() -> [Token]
    func isTokenEarnable(address: String) -> Bool
    func isFavoriteToken(address: String) -> Bool
    func markFavoriteToken(address: String, toOn: Bool)
}

public extension TokenStorage {
    
    func quoteToken(forChain chain: ChainType) -> Token {
        return AppDependencies.tokenStorage.getAllSupportedTokens().first { token in
            return token.symbol == chain.customRPC().quoteToken && token.address == chain.customRPC().quoteTokenAddress
        } ?? Token(name: chain.customRPC().quoteToken,
                   symbol: chain.customRPC().quoteToken,
                   address: chain.customRPC().quoteTokenAddress,
                   decimals: 18,
                   logo: chain.customRPC().quoteToken.lowercased())
    }
    
}
