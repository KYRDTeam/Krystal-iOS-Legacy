//
//  OverviewMainCellViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 26/07/2022.
//

import UIKit
import BigInt

enum OverviewMainCellMode {
  case market(token: Token, rightMode: RightMode)
  case asset(token: Token, rightMode: RightMode)
  case supply(balance: Any)
  case search(token: Token)
}

class OverviewMainCellViewModel {
  let mode: OverviewMainCellMode
  let currency: CurrencyMode
  var chainName: String = ""
  var chainId: Int = KNGeneralProvider.shared.currentChain.getChainId()
  var chainLogo: String = ""
  var balance: String = ""
  var decimals: Int = 0
  var quotes: [String: Quotes] = [:]
  var hideBalanceStatus: Bool = true
  var tag: String?
  init(mode: OverviewMainCellMode, currency: CurrencyMode) {
    self.mode = mode
    self.currency = currency
  }
  
  var tokenSymbol: String {
    switch self.mode {
    case .market(token: let token, _):
      return token.symbol
    case .asset(token: let token, _):
      return token.symbol
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        return lendingBalance.symbol
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        return distributionBalance.symbol
      } else {
        return ""
      }
    case .search(token: let token):
      return token.symbol
    }
  }
  
  var logo: String {
    switch self.mode {
    case .market(token: let token, rightMode: _):
      return token.logo
    case .asset(token: let token, rightMode: _):
      return token.logo
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        return lendingBalance.logo
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        return distributionBalance.logo
      }
      return ""
    case .search(token: let token):
      return token.symbol
    }
  }
  
  var displayTitle: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      return token.symbol
    case .asset(token: let token, rightMode: let mode):
      return token.symbol
    case .supply(balance: let balance):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      if let lendingBalance = balance as? LendingBalance {
        let balanceBigInt = BigInt(lendingBalance.supplyBalance) ?? BigInt(0)
        let balanceString = balanceBigInt.string(decimals: lendingBalance.decimals, minFractionDigits: 0, maxFractionDigits: 5)
        return "\(balanceString) \(lendingBalance.symbol)"
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        let balanceBigInt = BigInt(distributionBalance.unclaimed) ?? BigInt(0)
        let balanceString = balanceBigInt.string(decimals: distributionBalance.decimal, minFractionDigits: 0, maxFractionDigits: 5)
        return "\(balanceString) \(distributionBalance.symbol)"
      } else {
        return ""
      }
    case .search(token: let token):
      return token.symbol
    }
  }
  
  
  var multiChainSubTitle: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      let vol = token.getVol(self.currency)
      return "Vol: " + self.formatPoints(vol)
    case .asset(token: let token, rightMode: let mode):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      let balanceBigInt = self.balance.bigInt ?? BigInt(0)
      return balanceBigInt.string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: min(token.decimals, 5))
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        let rateString = String(format: "%.2f", lendingBalance.supplyRate * 100)
        return "\(rateString)%".paddingString()
      } else {
        return ""
      }
    case .search(token: let token):
      return token.name
    default:
      return ""
    }
  }
  
  var multiChainAccessoryTitle: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      let price = token.getTokenLastPrice(self.currency)
      let priceBigInt = BigInt(price * pow(10.0, 18.0))
        let valueString = priceBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 18).displayRate(meaningNumber: 2)
      return !self.currency.symbol().isEmpty ? self.currency.symbol() + valueString : valueString + self.currency.suffixSymbol()
    case .asset(token: _, rightMode: let mode):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      guard let quote = self.quotes[self.currency.toString()] else {
        return self.currency.symbol() + "0"
      }
      switch mode {
      case .value:
        let valueString = StringFormatter.currencyString(value: quote.value, symbol: self.currency.toString())
        return !self.currency.symbol().isEmpty ? self.currency.symbol() + valueString : valueString + self.currency.suffixSymbol()
      case .ch24:
        return String(format: "%.2f", quote.priceChange24hPercentage) + "%"
      case .lastPrice:
        let valueString = StringFormatter.currencyString(value: quote.price, symbol: self.currency.toString())
        return !self.currency.symbol().isEmpty ? self.currency.symbol() + valueString : valueString + self.currency.suffixSymbol()
      }
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        guard !self.hideBalanceStatus else {
          return "********"
        }
        let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: lendingBalance.address, currency: self.currency)
        let balanceBigInt = BigInt(lendingBalance.supplyBalance) ?? BigInt(0)
        let valueBigInt = balanceBigInt * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(lendingBalance.decimals)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currency.decimalNumber())
        return !self.currency.symbol().isEmpty ? self.currency.symbol() + valueString : valueString + self.currency.suffixSymbol()
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        guard !self.hideBalanceStatus else {
          return "********"
        }
        let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: distributionBalance.address, currency: self.currency)
        let balanceBigInt = BigInt(distributionBalance.unclaimed) ?? BigInt(0)
        let valueBigInt = balanceBigInt * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(distributionBalance.decimal)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: self.currency.decimalNumber())
        return !self.currency.symbol().isEmpty ? self.currency.symbol() + valueString : valueString + self.currency.suffixSymbol()
      } else {
        return ""
      }
    case .search(token: let token):
      let price = token.getTokenLastPrice(self.currency)
      return self.currency.symbol() + String(format: "%.2f", price)
    default:
      return ""
    }
  }

  var displaySubTitleDetail: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      let vol = token.getVol(self.currency)
      return "Vol: " + self.formatPoints(vol)
    case .asset(token: let token, rightMode: let mode):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      return token.getBalanceBigInt().string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: min(token.decimals, 5))
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        let rateString = String(format: "%.2f", lendingBalance.supplyRate * 100)
        return "\(rateString)%".paddingString()
      } else {
        return ""
      }
    case .search(token: let token):
      return token.name
    }
  }
  
  var multichainAccessoryTextColor: UIColor? {
    switch self.mode {
    case .market, .search:
      return UIColor(named: "textWhiteColor")
    case .asset(token: _, rightMode: _):
      guard let quote = self.quotes[self.currency.toString()] else {
        return UIColor(named: "buttonBackgroundColor")
      }
      return quote.priceChange24hPercentage > 0 ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "textRedColor")
    default:
      return UIColor(named: "buttonBackgroundColor")
    }
  }

  var displayDetailBox: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      switch mode {
      case .ch24:
        let change24 = token.getTokenChange24(self.currency)
        if change24 == 0 {
          return "---"
        }
        let prefix = change24 > 0 ? "+" : ""
        return prefix + String(format: "%.2f", change24) + "%"
      default:
        let mc = token.getMarketCap(self.currency)
        if mc == 0 {
          return "---"
        }
        return self.currency.symbol() + self.formatPoints(mc)
      }
    case .search(token: let token):
      let change24 = token.getTokenChange24(self.currency)
      return String(format: "%.2f", change24) + "%"
    default:
      return ""
    }
  }
  
  var tagImage: UIImage? {
    guard let tag = self.tag else { return nil }
    return UIImage.imageWithTag(tag: tag)
  }
  
  func formatPoints(_ number: Double) -> String {
    let thousand = number / 1000
    let million = number / 1000000
    let billion = number / 1000000000
    
    if billion >= 1.0 {
      return "\(round(billion*10)/10)B"
    } else if million >= 1.0 {
      return "\(round(million*10)/10)M"
    } else if thousand >= 1.0 {
      return ("\(round(thousand*10/10))K")
    } else {
      return "\(Int(number))"
    }
  }
}
