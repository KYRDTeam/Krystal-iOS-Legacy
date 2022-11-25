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
    let vc = TokenDetailViewController.instantiateFromNib()
    let viewModel = TokenDetailViewModel(address: address, chain: chain, currencyMode: currencyMode)
    vc.viewModel = viewModel
    return vc
  }
  
}
