// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt

struct KNDraftExchangeTransaction {
  let from: TokenObject
  let to: TokenObject
  let amount: BigInt
  let maxDestAmount: BigInt
  let expectedRate: BigInt
  let minRate: BigInt?
  let gasPrice: BigInt?
  let gasLimit: BigInt?
  let expectedReceivedString: String?
  let hint: String?
}

extension KNDraftExchangeTransaction {
  func displayAmount(short: Bool = true) -> String {
    return short ? amount.shortString(decimals: from.decimals) : amount.fullString(decimals: from.decimals)
  }

  var expectedReceive: BigInt {
    return amount * expectedRate * BigInt(10).power(to.decimals) / BigInt(10).power(from.decimals) / BigInt(10).power(18)
  }

  func displayExpectedReceive(short: Bool = true) -> String {
    if let string = self.expectedReceivedString {
      return "\(string.prefix(15))"
    }
    return short ? expectedReceive.shortString(decimals: to.decimals) : expectedReceive.fullString(decimals: to.decimals)
  }

  func displayExpectedRate(short: Bool = true) -> String {
    return short ? expectedRate.shortString(decimals: 18) : expectedRate.fullString(decimals: 18)
  }

  func displayMinRate(short: Bool = true) -> String? {
    return short ? minRate?.shortString(decimals: to.decimals) : minRate?.fullString(decimals: to.decimals)
  }

  var displayGasPrice: String? {
    return gasPrice?.shortString(units: UnitConfiguration.gasPriceUnit)
  }

  var fee: BigInt {
    return (gasPrice ?? BigInt(0)) * (gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault)
  }

  func displayFeeString(short: Bool = true) -> String {
    return short ? fee.shortString(units: UnitConfiguration.gasFeeUnit) : fee.fullString(units: UnitConfiguration.gasFeeUnit)
  }

  var usdValueStringForFee: String {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.to.address) else { return "" }
    let feeUSD = self.fee * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(self.to.decimals)
    return feeUSD.shortString(units: .ether)
  }

  var usdValueStringForFromToken: String {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.to.address) else { return "" }
    let feeUSD = self.amount * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(self.from.decimals)
    return feeUSD.shortString(units: .ether)
  }

}

extension KNDraftExchangeTransaction {

  func copy(expectedRate: BigInt, gasLimit: BigInt? = nil) -> KNDraftExchangeTransaction {
    return KNDraftExchangeTransaction(
      from: self.from,
      to: self.to,
      amount: self.amount,
      maxDestAmount: self.maxDestAmount,
      expectedRate: expectedRate,
      minRate: self.minRate,
      gasPrice: self.gasPrice,
      gasLimit: gasLimit ?? self.gasLimit,
      expectedReceivedString: (expectedRate * amount / BigInt(10).power(self.from.decimals)).fullString(decimals: self.to.decimals),
      hint: self.hint
    )
  }
}
