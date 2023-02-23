//
//  TokenListViewModel.swift
//  TokenModule
//
//  Created by Tung Nguyen on 17/02/2023.
//

import Foundation
import ChainModule
import Services

class TokenListViewModel {
    var commonBaseTokens: [Services.Token] = []
    var items: [TokenItemCellViewModel]
    var walletAddress: String
    let chainID: Int
    
    init(walletAddress: String, chainID: Int) {
        self.chainID = chainID
        self.walletAddress = walletAddress
        self.items = TokenDB.shared.allTokens().toViewModels(walletAddress: walletAddress)
    }
    
    func fetchCommonBaseTokens(completion: @escaping () -> ()) {
        if let apiPath = ChainDB.shared.getConfig(chainID: chainID, key: kChainApiPath) {
            TokenService().getCommonBaseTokens(chainPath: apiPath) { tokens in
                self.commonBaseTokens = tokens
                completion()
            }
        }
    }
    
    func search(query: String) {
        if query.trimmed.isEmpty {
            items = TokenDB.shared.allTokens().toViewModels(walletAddress: walletAddress)
        } else {
            items = TokenDB.shared.search(query: query.trimmed).toViewModels(walletAddress: walletAddress)
        }
    }
}
