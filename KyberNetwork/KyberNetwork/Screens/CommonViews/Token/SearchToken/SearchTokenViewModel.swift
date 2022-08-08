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

  func fetchDataFromAPI(querry: String, orderBy: String, completion: @escaping () -> Void) {
    SearchSwapTokenService.getSearchTokens(address: AppDelegate.session.address.addressString, querry: querry, orderBy: orderBy) { swapTokens in
      if let swapTokens = swapTokens {
        self.searchTokens = swapTokens
        completion()
      }
    }
  }
  
  func getCommonBaseToken(completion: @escaping () -> Void) {
    SearchSwapTokenService.getCommonBaseTokens { tokens in
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
