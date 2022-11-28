//
//  AppTokenStorage.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation
import Dependencies

class AppTokenStorage: TokenStorage {
  
  func isTokenEarnable(address: String) -> Bool {
    let lendingTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName, as: [TokenData].self) ?? []
    return lendingTokens.contains(where: { token in
      return token.address.lowercased() == address.lowercased()
    })
  }
  
  func getAllSupportedTokens() -> [Token] {
    return KNSupportedTokenStorage.shared.allFullToken
  }
  
  func isFavoriteToken(address: String) -> Bool {
    return KNSupportedTokenStorage.shared.getFavedStatusWithAddress(address)
  }
  
  func markFavoriteToken(address: String, toOn: Bool) {
    KNSupportedTokenStorage.shared.setFavedStatusWithAddress(address, status: toOn)
  }
}
