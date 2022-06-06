// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import JdenticonSwift

struct KConfirmSendViewModel {
  let solTransaction: UnconfirmedSolTransaction?
  let transaction: UnconfirmedTransaction?
  let ens: String?

  init(transaction: UnconfirmedTransaction? = nil, ens: String? = nil, solTransaction: UnconfirmedSolTransaction? = nil) {
    self.transaction = transaction
    self.ens = ens
    self.solTransaction = solTransaction
  }

  var token: TokenObject {
    if let solTransaction = self.solTransaction {
      return solTransaction.transferType.tokenObject()
    }
    if let transaction = transaction {
      return transaction.transferType.tokenObject()
    }
    return TokenObject()
  }

  var addressToIcon: UIImage? {
    if let solTransaction = self.solTransaction {
      guard let data = SolanaUtil.convertBase58Data(addressString: solTransaction.to) else { return nil }
      return UIImage.generateImage(with: 75, hash: data)
    } else {
      guard let data = self.transaction?.to?.data else { return nil }
      return UIImage.generateImage(with: 75, hash: data)
    }
  }

  var titleString: String {
    return "Sending confirm".toBeLocalised().uppercased()
  }

  var contactName: String {
    var address = ""
    if let solTransaction = self.solTransaction {
      address = solTransaction.to
    } else {
      address = transaction?.to?.description ?? NSLocalizedString("not.in.contact", value: "Not In Contact", comment: "")
    }
    guard let contact = KNContactStorage.shared.contacts.first(where: { address.lowercased() == $0.address.lowercased() }) else {
      let text = NSLocalizedString("not.in.contact", value: "Not In Contact", comment: "")
      if let ens = self.ens { return "\(ens) - \(text)" }
      return text
    }
    if let ens = self.ens { return "\(ens) - \(contact.name)" }
    return contact.name
  }

  var address: String {
    if let solTransaction = self.solTransaction {
      return "\(solTransaction.to.prefix(20))...\(solTransaction.to.suffix(8))"
    }
    let address = transaction?.to?.description ?? ""
    return "\(address.prefix(20))...\(address.suffix(8))"
  }

  var shortAddress: String {
    var address = ""
    if let solTransaction = self.solTransaction {
      address = solTransaction.to
    } else {
      address = transaction?.to?.description ?? ""
    }
    return "\(address.prefix(6))...\(address.suffix(6))"
  }

  var totalAmountString: String {
    if let solTransaction = self.solTransaction {
      let string = solTransaction.value.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: self.token.decimals)
      return "\(string.prefix(15)) \(self.token.symbol)"
    }
    let string = self.transaction?.value.string(
      decimals: self.token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.token.decimals, 6)
    ) ?? ""
    return "\(string.prefix(15)) \(self.token.symbol)"
  }

  var usdValueString: String {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address) else { return "" }
//    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else { return "" }
    let displayString: String = {
      let usd = self.transaction?.value ?? BigInt(1) * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.token.decimals)
    return usd.string(
      units: EthereumUnit.ether,
      minFractionDigits: 0,
      maxFractionDigits: 4
    )
    }()
    return "~ \(displayString) USD"
  }

  var transactionFeeText: String { return "\(NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")): " }
  var transactionFeeETHString: String {
    if let solTransaction = self.solTransaction {
      return solTransaction.fee.string(decimals: 9, minFractionDigits: 0, maxFractionDigits: 9) + " \(KNGeneralProvider.shared.quoteToken)"
    }
    let fee: BigInt? = {
      guard let gasPrice = self.transaction?.gasPrice, let gasLimit = self.transaction?.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  var transactionFeeUSDString: String {
    let fee: BigInt? = {
      guard let gasPrice = self.transaction?.gasPrice, let gasLimit = self.transaction?.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    guard let feeBigInt = fee else { return "" }
//    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
//    let feeUSD: String = {
//      let fee = feeBigInt * trackerRate.rateUSDBigInt / BigInt(EthereumUnit.ether.rawValue)
//      return fee.displayRate(decimals: 18)
//    }()
//    return "~ \(feeUSD) USD"
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = feeBigInt * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }
  var transactionGasPriceString: String {
    if let solTransaction = self.solTransaction {
      return ""
//      return String(format: NSLocalizedString("%@ (Lamport) * %@ (Signatures)", comment: ""), solTransaction.lamportPerSignature.displayRate(decimals: 0), solTransaction.totaSignature.displayRate(decimals: 0))
    }
    let gasPrice: BigInt = self.transaction?.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.transaction?.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    let gasPriceText = gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 5
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }
}
