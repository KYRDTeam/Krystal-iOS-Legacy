//
//  SearchTokenViewModel.swift
//  TokenModule
//
//  Created by Com1 on 01/12/2022.
//

import UIKit
import Services
import BaseModule
import Services
import ChainModule

public class SearchTokenViewModel: BaseViewModel {
    var commonBaseTokens: [Services.Token] = []
    var searchTokens: [SearchToken] = []
    let searchService = TokenService()
    var foundTokens: [ChainModule.Token] = TokenDB.shared.allTokens()
    
    func search(query: String) {
        foundTokens = TokenDB.shared.search(query: query)
    }
    
    func fetchDataFromAPI(query: String, orderBy: String, completion: @escaping () -> Void) {
        self.searchService.getSearchTokens(chainPath: currentChain.customRPC().apiChainPath,address: currentAddress.addressString, query: query, orderBy: orderBy) { [weak self] swapTokens in
            if let swapTokens = swapTokens {
              self?.searchTokens = swapTokens
            }
            completion()
        }
    }
    
    func getCommonBaseToken(completion: @escaping () -> Void) {
        self.searchService.getCommonBaseTokens(chainPath: currentChain.customRPC().apiChainPath) { [weak self] tokens in
            self?.commonBaseTokens = tokens
            completion()
        }
    }
    
    func numberOfCommonBaseTokens() -> Int {
      return commonBaseTokens.count
    }
    
    func numberOfSearchTokens() -> Int {
      return searchTokens.count
    }
    
    func numberOfTokens() -> Int {
      return self.searchTokens.count
    }
}
