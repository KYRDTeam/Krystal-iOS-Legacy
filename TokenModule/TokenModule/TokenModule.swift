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

public class TokenModule {
  
  public static var apiURL: String!
  
  public static func createTokenDetailViewController(address: String, chain: ChainType) -> UIViewController {
    let vc = TokenDetailViewController.instantiateFromNib()
    return vc
  }
  
}
