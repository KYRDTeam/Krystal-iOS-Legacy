//
//  CurrencyMode+.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 23/11/2022.
//

import Foundation
import BaseWallet
import AppState

extension CurrencyMode {
  
  func suffixSymbol() -> String {
    return suffixSymbol(chain: AppState.shared.currentChain)
  }

  public func toString() -> String {
    return toString(chain: AppState.shared.currentChain)
  }
  
}
