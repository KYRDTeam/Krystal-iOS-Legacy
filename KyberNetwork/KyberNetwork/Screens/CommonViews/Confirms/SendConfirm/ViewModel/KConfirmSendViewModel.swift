// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import JdenticonSwift
import Utilities

struct KConfirmSendViewModel {
  let transaction: UnconfirmedTransaction
  let ens: String?
  
  var currentChain = KNGeneralProvider.shared.currentChain

  init(transaction: UnconfirmedTransaction, ens: String? = nil) {
    self.transaction = transaction
    self.ens = ens
  }

  var token: TokenObject {
    return transaction.transferType.tokenObject()
  }

  var addressToIcon: UIImage? {
    switch currentChain {
    case .solana:
      guard let data = SolanaUtil.convertBase58Data(addressString: transaction.to ?? "") else { return nil }
      return UIImage.generateImage(with: 75, hash: data)
    default:
      guard let to = self.transaction.to, let data = Data(hexString: to) else { return nil }
      return UIImage.generateImage(with: 75, hash: data)
    }
  }

  var titleString: String {
    return "Sending confirm".toBeLocalised().uppercased()
  }

  var contactName: String {
    guard let contact = KNContactStorage.shared.contacts.first(where: { $0.address == transaction.to }) else {
      if let ens = ens {
        return "\(ens) - \(Strings.notInContact)"
      }
      return Strings.notInContact
    }
    guard let ens = ens else {
      return contact.name
    }
    return "\(ens) - \(contact.name)"
  }

  var address: String {
    guard let to = transaction.to else { return "" }
    switch currentChain {
    case .solana:
      return "\(to.prefix(20))...\(to.suffix(8))"
    default:
      return "\(to.prefix(20))...\(to.suffix(8))"
    }
  }

  var shortAddress: String {
    guard let to = transaction.to else { return "" }
    return "\(to.prefix(6))...\(to.suffix(6))"
  }

  var totalAmountString: String {
    return "\(NumberFormatUtils.balanceFormat(value: self.transaction.value, decimals: self.token.decimals)) \(self.token.symbol)"
  }
    
    var displayValue: String {
        guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address) else { return "" }

        let displayString: String = {
          let usd = self.transaction.value * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.token.decimals)
          return usd.string(
            units: EthereumUnit.ether,
            minFractionDigits: 0,
            maxFractionDigits: 4
          )
        }()
        return displayString
    }

  var usdValueString: String {
      let display = self.displayValue
      guard !display.isEmpty else { return "" }

    return "~ \(display) USD"
  }

  var transactionFeeText: String { return "\(Strings.transactionFee): " }

  var transactionFeeETHString: String {
    switch currentChain {
    case .solana:
      let fee = transaction.estimatedFee ?? BigInt(0)
      return NumberFormatUtils.balanceFormat(value: fee, decimals: 9) + " \(KNGeneralProvider.shared.quoteToken)"
    default:
      let fee: BigInt? = {
        guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.transaction.gasLimit else { return nil }
        return gasPrice * gasLimit
      }()
      var feeString = "---"
      if let fee = fee {
        feeString = NumberFormatUtils.balanceFormat(value: fee, decimals: 18)
      }
        
      return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
    }
  }

  var transactionFeeUSDString: String {
    let fee: BigInt? = {
      guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.transaction.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    guard let feeBigInt = fee else { return "" }
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = feeBigInt * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var transactionGasPriceString: String {
    switch currentChain {
    case .solana:
      return ""
    default:
      let gasPrice: BigInt = self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
      let gasLimit: BigInt = self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
      let gasPriceText = gasPrice.shortString(
        units: .gwei,
        maxFractionDigits: 5
      )
      let gasLimitText = EtherNumberFormatter.short.string(from: gasLimit, decimals: 0)
      let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
      return labelText
    }
  }
}
