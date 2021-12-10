// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KConfirmSwapViewModel {

  let transaction: KNDraftExchangeTransaction
  let ethBalance: BigInt
  let signTransaction: SignTransaction?
  let priceImpact: Double
  let platform: String
  let rawTransaction: TxObject
  let minReceiveAmount: String
  let minReceiveTitle: String
  let eip1559Transaction: EIP1559Transaction?

  init(
    transaction: KNDraftExchangeTransaction,
    ethBalance: BigInt,
    signTransaction: SignTransaction?,
    eip1559Tx: EIP1559Transaction?,
    priceImpact: Double,
    platform: String,
    rawTransaction: TxObject,
    minReceiveAmount: String,
    minReceiveTitle: String
  ) {
    self.transaction = transaction
    self.ethBalance = ethBalance
    self.signTransaction = signTransaction
    self.priceImpact = priceImpact
    self.platform = platform
    self.rawTransaction = rawTransaction
    self.eip1559Transaction = eip1559Tx
    self.minReceiveAmount = minReceiveAmount
    self.minReceiveTitle = minReceiveTitle
  }

  var titleString: String {
    return "\(self.transaction.from.symbol) ➞ \(self.transaction.to.symbol)"
  }

  var leftAmountString: String {
    let amountString = self.transaction.amount.displayRate(decimals: transaction.from.decimals)
    return "\(amountString.prefix(15)) \(self.transaction.from.symbol)"
  }

  var equivalentUSDAmount: BigInt? {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.transaction.to.address) else { return nil }
    let usd = self.transaction.expectedReceive * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.transaction.to.decimals)
    return usd
  }

  var fromUSDAmount: BigInt? {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.transaction.from.address) else { return nil }
    let usd = self.transaction.amount * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.transaction.from.decimals)
    return usd
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: DecimalNumber.usd)
    if let doubleValue = Double(value), doubleValue < 0.01 {
      return ""
    }
    return "~ $\(value) USD"
  }

  var displayFromUSDAmount: String? {
    guard let amount = self.fromUSDAmount, !amount.isZero else { return nil }
    let value = amount.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: DecimalNumber.usd)
    if let doubleValue = Double(value), doubleValue < 0.01 {
      return ""
    }
    return "~ $\(value) USD"
  }

  var rightAmountString: String {
    let receivedAmount = self.transaction.displayExpectedReceive(short: false)
    return "\(receivedAmount.prefix(15)) \(self.transaction.to.symbol)"
  }

  var displayEstimatedRate: String {
    let rateString = self.transaction.expectedRate.displayRate(decimals: 18)
    return "1 \(self.transaction.from.symbol) = \(rateString) \(self.transaction.to.symbol)"
  }

  var warningMinAcceptableRateMessage: String? {
    guard let minRate = self.transaction.minRate, minRate >= self.transaction.expectedRate else { return nil }
    // min rate is zero
    return "Your configured minimal rate is higher than what is recommended by KyberNetwork. Your swap has high chance to fail.".toBeLocalised()
  }

  var minRateString: String {
    let minRate = self.transaction.minRate ?? BigInt(0)
    return minRate.displayRate(decimals: 18)
  }

  var transactionFee: BigInt {
    let gasPrice: BigInt = self.transactionGasPrice
    let gasLimit: BigInt = self.transactionGasLimit
    return gasPrice * gasLimit
  }

  var feeETHString: String {
    let quoteToken = KNGeneralProvider.shared.quoteToken
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) \(quoteToken)"
  }

  var feeUSDString: String {
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.transactionFee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: DecimalNumber.usd)
    if let doubleValue = Double(valueString), doubleValue < 0.01 {
      return ""
    }
    return "~ \(valueString) USD"
  }

  var warningETHBalanceShown: Bool {
    if !self.transaction.from.isETH { return false }
    let totalAmount = self.transactionFee + self.transaction.amount
    return self.self.transaction.from.getBalanceBigInt() - totalAmount <= BigInt(0.01 * pow(10.0, 18.0))
  }

  var transactionGasPriceString: String {
    let gasPrice: BigInt = self.transactionGasPrice
    let gasLimit: BigInt = self.transactionGasLimit
    let gasPriceText = gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }

  var hint: String {
    return self.transaction.hint ?? ""
  }
  
  var transactionGasPrice: BigInt {
    if KNGeneralProvider.shared.isUseEIP1559 {
      if let unwrap = self.eip1559Transaction?.maxGasFee, let gasPrice = BigInt(unwrap.drop0x, radix: 16) {
        return gasPrice
      } else {
        return BigInt(0)
      }
    } else {
      return self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    }
  }

  var transactionGasLimit: BigInt {
    if KNGeneralProvider.shared.isUseEIP1559 {
      if let unwrap = self.eip1559Transaction?.gasLimit, let gasLimit = BigInt(unwrap.drop0x, radix: 16) {
        return gasLimit
      } else {
        return BigInt(0)
      }
    } else {
      return self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    }
  }

  var reverseRoutingText: String {
    return self.priceImpact > -5 ? String(format: "Your transaction will be routed to %@ for better rate.".toBeLocalised(), self.platform.capitalized) : ""
  }

  var warningETHText: String {
    return self.warningETHBalanceShown ? "After this swap you will not have enough ETH for further transactions.".toBeLocalised() : ""
  }
  
  var priceImpactText: String {
    guard self.priceImpact != -1000 else { return " Missing price impact. Please swap with caution." }
    return self.priceImpact > -5 ? "" : "Price impact is high. You may want to reduce your swap amount for a better rate."
  }

  var priceImpactValueText: String {
    guard self.priceImpact != -1000.0 else { return "---" }
    return StringFormatter.percentString(value: self.priceImpact / 100)
  }

  var priceImpactValueTextColor: UIColor? {
    guard self.priceImpact != -1000.0 else { return UIColor(named: "normalTextColor") }
    let change = self.priceImpact
    if change <= -5.0 {
      return UIColor(named: "textRedColor")
    } else if change <= -2.0 {
      return UIColor(named: "warningColor")
    } else {
      return UIColor(named: "textWhiteColor")
    }
  }
  
  var hasPriceImpact: Bool {
    return self.priceImpact <= -20
  }
}
