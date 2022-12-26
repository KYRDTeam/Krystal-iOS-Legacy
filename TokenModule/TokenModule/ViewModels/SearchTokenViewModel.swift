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

public class SearchTokenViewModel: BaseViewModel {
    var commonBaseTokens: [Token] = []
    var searchTokens: [SearchToken] = []
    let searchService = TokenService()
    
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
