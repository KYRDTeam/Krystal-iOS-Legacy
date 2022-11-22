//
//  CurrencyMode.swift
//  AppState
//
//  Created by Tung Nguyen on 22/11/2022.
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

  public func suffixSymbol() -> String {
    switch self {
    case .quote:
      return " \(AppState.shared.currentChain.customRPC().quoteToken)"
    default:
      return ""
    }
  }

  public func toString() -> String {
    switch self {
    case .eth:
      return "eth"
    case .usd:
      return "usd"
    case .btc:
      return "btc"
    case .quote:
      return AppState.shared.currentChain.customRPC().quoteToken.lowercased()
    }
  }

  public var isQuoteCurrency: Bool {
    return self == .quote
  }
}
