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
        let defaultTokenImageUrl = "https://files.kyberswap.com/DesignAssets/tokens/iOS/%@.png"
        let tokenSymbol = chain.customRPC().quoteToken
        return AppDependencies.tokenStorage.getAllSupportedTokens().first { token in
            return token.symbol == tokenSymbol && token.address == chain.customRPC().quoteTokenAddress
        } ?? Token(name: chain.customRPC().quoteToken,
                   symbol: chain.customRPC().quoteToken,
                   address: chain.customRPC().quoteTokenAddress,
                   decimals: 18,
                   logo: String(format: defaultTokenImageUrl, tokenSymbol.lowercased()))
    }
    
}
