//
//  SearchTokenViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 05/08/2022.
//

import UIKit

class SearchTokenViewModel: NSObject {
  var commonBaseTokens: [Token] = []
  var searchTokens: [SwapToken] = []
  let searchService = SearchSwapTokenService()
  
  func fetchDataFromAPI(query: String, orderBy: String, completion: @escaping () -> Void) {
    self.searchService.getSearchTokens(address: AppDelegate.session.address.addressString, query: query, orderBy: orderBy) { swapTokens in
      if let swapTokens = swapTokens {
        self.searchTokens = swapTokens
      }
      completion()
    }
  }
  
  func getCommonBaseToken(completion: @escaping () -> Void) {
    self.searchService.getCommonBaseTokens { tokens in
      if let tokens = tokens {
        self.commonBaseTokens = tokens
        completion()
      }
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
