//
//  ApiTokenSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import RealmSwift

class ApiTokenSyncOperation: TokenSyncOperation {
    
    let chainID: Int
    
    init(chainID: Int) {
        self.chainID = chainID
    }
    
    override func execute(completion: @escaping () -> ()) {
        if let apiPath = ChainDB.shared.getConfig(chainID: chainID, key: kChainApiPath) {
            TokenService().getTokenList(chainPath: apiPath) { tokens in
                TokenDB.shared.save(tokens: tokens.map { self.convertToTokenObject(chainID: self.chainID, token: $0) })
                self.updateNativeTokenInfo(chainID: self.chainID, tokens: tokens)
            }
            completion()
        } else {
            completion()
        }
    }
    
    func updateNativeTokenInfo(chainID: Int, tokens: [TokenModel]) {
        let realm = try! Realm()
        let nativeTokens = realm.objects(TokenEntity.self).filter { token in
            return token.isNativeToken && token.chainID == chainID
        }
        if !nativeTokens.isEmpty {
            try! realm.write {
                nativeTokens.forEach { nativeToken in
                    if let foundToken = tokens.first(where: { $0.chainId == nativeToken.chainID && $0.symbol == nativeToken.symbol }) {
                        nativeToken.iconUrl = foundToken.logo
                        nativeToken.name = foundToken.name
                    }
                }
            }
        }
    }
    
    private func convertToTokenObject(chainID: Int, token: TokenModel) -> TokenEntity {
        return TokenEntity(chainID: chainID,
                           address: token.address,
                           iconUrl: token.logo,
                           decimal: token.decimals,
                           symbol: token.symbol,
                           name: token.name,
                           tag: token.tag,
                           type: erc20TokenType,
                           isAddedByUser: false)
    }
    
}
