//
//  TokenModule.swift
//  TokenModule
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation
import UIKit
import Utilities
import BaseWallet
import Dependencies

public class TokenModule {
  
  public static var apiURL: String!
  
  public static func createTokenDetailViewController(address: String, chain: ChainType, currencyMode: CurrencyMode) -> UIViewController? {
    guard let token = AppDependencies.tokenStorage.getAllSupportedTokens().first(where: { token in
      token.address.lowercased() == address.lowercased()
    }) else { return nil }
    let vc = TokenDetailViewController.instantiateFromNib()
    let viewModel = TokenDetailViewModel(token: token, chainID: chain.getChainId(), currencyMode: currencyMode)
    vc.viewModel = viewModel
    return vc
  }
  
}
