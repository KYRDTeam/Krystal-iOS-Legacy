// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import BigInt
import Utilities

class KNTrackerRate: Object {
  @objc dynamic var timestamp: Double = 0.0
  @objc dynamic var tokenName: String = ""
  @objc dynamic var tokenSymbol: String = ""
  @objc dynamic var tokenDecimals: Int = 0
  @objc dynamic var tokenAddress: String = ""
  @objc dynamic var rateETHNow: Double = 0.0
  @objc dynamic var changeETH24h: Double = 0.0
  @objc dynamic var rateUSDNow: Double = 0.0
  @objc dynamic var changeUSD24h: Double = 0.0

  convenience init(dict: JSONDictionary) {
    self.init()
    self.timestamp = dict["timestamp"] as? Double ?? 0.0
    self.tokenName = dict["token_name"] as? String ?? ""
    self.tokenSymbol = dict["token_symbol"] as? String ?? ""
    self.tokenDecimals = dict["token_decimal"] as? Int ?? 0
    self.tokenAddress = dict["token_address"] as? String ?? ""
    self.rateETHNow = dict["rate_eth_now"] as? Double ?? 0.0
    self.changeETH24h = dict["change_eth_24h"] as? Double ?? 0.0
    self.changeUSD24h = dict["change_usd_24h"] as? Double ?? 0.0
    self.rateUSDNow = dict["rate_usd_now"] as? Double ?? 0.0
  }

  var rateETHBigInt: BigInt {
    return BigInt(self.rateETHNow * Double(EthereumUnit.ether.rawValue))
  }

  var rateUSDBigInt: BigInt {
    return BigInt(self.rateUSDNow * Double(EthereumUnit.ether.rawValue))
  }

  override static func primaryKey() -> String {
    return "tokenAddress"
  }
}

extension KNTrackerRate {
  func isTrackerRate(for token: TokenObject) -> Bool {
    if KNEnvironment.default == .kovan || KNEnvironment.default == .ropsten || KNEnvironment.default == .rinkeby {
      return self.tokenSymbol == token.symbol
    }
    return self.tokenAddress.lowercased() == token.contract.lowercased()
  }

  var identifier: String {
    if KNEnvironment.default == .kovan || KNEnvironment.default == .ropsten || KNEnvironment.default == .rinkeby {
      return self.tokenSymbol
    }
    return self.tokenAddress.lowercased()
  }
}
