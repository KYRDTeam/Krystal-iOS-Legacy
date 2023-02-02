//
//  ApiTokenSyncOperation.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation

class ApiTokenSyncOperation: TokenSyncOperation {
    
    let chainID: Int
    
    init(chainID: Int) {
        self.chainID = chainID
    }
    
    override func execute(completion: @escaping () -> ()) {
        if let apiPath = ChainDB.shared.getConfig(chainID: chainID, key: kChainApiPath) {
            TokenService().getTokenList(chainPath: apiPath) { tokens in
                TokenDB.shared.save(tokens: tokens.map { self.convertToTokenObject(chainID: self.chainID, token: $0) })
                completion()
            }
        } else {
            completion()
        }
    }
    
    private func convertToTokenObject(chainID: Int, token: TokenModel) -> TokenEntity {
        return TokenEntity(chainID: chainID,
                           address: token.address,
                           iconUrl: token.logo,
                           decimal: token.decimals,
                           symbol: token.symbol,
                           name: token.name,
                           isAddedByUser: false)
    }
    
}
