//
//  TokenSelectViewModel.swift
//  TokenModule
//
//  Created by Tung Nguyen on 23/12/2022.
//

import Foundation
import Services

public class TokenSelectViewModel {
    
    var tokens: [AdvancedSearchToken] = []
    
    var query: String = "" {
        didSet {
            if query.isEmpty {
                self.tokens = []
                self.onTokensUpdated?()
            } else {
                self.search()
            }
        }
    }
    var onTokensUpdated: (() -> ())?
    
    let service = TokenService()
    
    public init() {
        
    }
    
    func search() {
        service.advancedSearch(query: query) { [weak self] tokens in
            self?.tokens = tokens
            self?.onTokensUpdated?()
        }
    }
    
}
