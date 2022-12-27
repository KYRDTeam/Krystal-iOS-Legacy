//
//  TokenSelectViewModel.swift
//  TokenModule
//
//  Created by Tung Nguyen on 23/12/2022.
//

import Foundation
import Services
import BaseWallet

public class TokenSelectViewModel {
    
    var tokens: [AdvancedSearchToken] = []
    var query: String = ""
    var onTokensUpdated: (() -> ())?
    
    let service = TokenService()
    
    public init() {
        
    }
    
    func updateQuery(query: String, chainType: ChainType) {
        self.query = query
        if query.isEmpty {
            self.tokens = []
            self.onTokensUpdated?()
        } else {
            self.search(chainType: chainType)
        }
    }
    
    func search(chainType: ChainType) {
        service.advancedSearch(query: query) { [weak self] tokens in
            if chainType == .all {
                self?.tokens = tokens
            } else {
                self?.tokens = tokens.filter { $0.chainId == chainType.getChainId() }
            }
            self?.onTokensUpdated?()
        }
    }
    
}
