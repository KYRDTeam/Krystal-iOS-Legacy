//
//  CurrencyMode.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 23/11/2022.
//

import Foundation

public enum CurrencyMode: Int {
  case usd = 0
  case eth
  case btc
  case quote

  public func symbol() -> String {
    switch self {
    case .usd:
      return "$"
    case .btc:
      return "₿"
    case .eth:
      return "⧫"
    case .quote:
      return ""
    }
  }

  public func suffixSymbol(chain: ChainType) -> String {
    switch self {
    case .quote:
      return " \(chain.customRPC().quoteToken)"
    default:
      return ""
    }
  }

  public func toString(chain: ChainType) -> String {
    switch self {
    case .eth:
      return "eth"
    case .usd:
      return "usd"
    case .btc:
      return "btc"
    case .quote:
      return chain.customRPC().quoteToken.lowercased()
    }
  }

  public var isQuoteCurrency: Bool {
    return self == .quote
  }
}
