//
//  DappBrowerTransactionConfirmViewModel.swift
//  DappBrowser
//
//  Created by Com1 on 14/02/2023.
//

import UIKit
import TransactionModule
import BigInt
import Utilities
import AppState
import Dependencies
import BaseWallet

class DappBrowerTransactionConfirmViewModel {
    let transaction: LegacyTransaction
    let webPageInfo: WebPageInfo
    var onSign: ((TxSettingObject) -> Void)?
    var onCancel: (() -> Void)?
    var onChangeGasFee: ((TxSettingObject) -> Void)?
    var settingObject: TxSettingObject
    

    init(transaction: LegacyTransaction, webPageInfo: WebPageInfo, settingObject: TxSettingObject) {
        self.transaction = transaction
        self.webPageInfo = webPageInfo
        self.settingObject = settingObject
    }

    var displayFromAddress: String {
        return transaction.address
    }

    var valueBigInt: BigInt {
      return BigInt(self.transaction.value)
    }

    var displayValue: String {
      let prefix = self.valueBigInt.isZero ? "" : "-"
      return prefix + "\(self.valueBigInt.shortString(decimals: 18)) \(AppState.shared.currentChain.quoteToken())"
    }

    var displayValueUSD: String {
      let price = AppDependencies.priceStorage.getQuoteUsdRate(chain: AppState.shared.currentChain) ?? 0
      let usd = self.valueBigInt * BigInt(price * pow(10.0, 18.0)) / BigInt(10).power(18)

      let valueString: String = usd.shortString(decimals: 18)
      return "≈ $\(valueString)"
    }
    
    var transactionFee: BigInt {
        if let basic = settingObject.basic {
            return settingObject.gasLimit * self.getGasPrice(gasType: basic.gasType)
        } else if let advance = settingObject.advanced {
            return settingObject.gasLimit * advance.maxFee
        }
        return BigInt(0)
    }

    var transactionFeeETHString: String {
        let feeString: String = NumberFormatUtils.gasFee(value: transactionFee)
        return "\(feeString) \(AppState.shared.currentChain.quoteToken())"
    }

    var transactionFeeUSDString: String {
        guard let price = AppDependencies.priceStorage.getQuoteUsdRate(chain: AppState.shared.currentChain) else { return "" }
        let usd = self.transactionFee * BigInt(price * pow(10, 18)) / BigInt(10).power(18)
        let valueString = NumberFormatUtils.gasFee(value: usd)
        return "~ \(valueString) USD"
    }

    var transactionGasPriceString: String {
        var gasPrice: BigInt {
            if let basic = settingObject.basic {
                return self.getGasPrice(gasType: basic.gasType)
            } else if let advance = settingObject.advanced {
                return advance.maxFee
            } else {
                return self.getGasPrice(gasType: .regular)
            }
        }
      let gasPriceText = gasPrice.shortString(
        units: .gwei,
        maxFractionDigits: 5
      )
      let gasLimitText = EtherNumberFormatter.short.string(from: self.settingObject.gasLimit, decimals: 0)
      let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
      return labelText
    }

    var imageIconURL: String {
        return webPageInfo.icon ?? ""
    }

    var isApproveTx: Bool {
      return self.transaction.data.hexEncoded.prefix(10) == "0x095ea7b3" //Constants.methodIdApprove
    }

    func getGasPrice(gasType: GasSpeed) -> BigInt {
        return GasPriceManager.shared.getGasPrice(gasType: gasType, chain: AppState.shared.currentChain)
    }
    
    func buildApproveMsg(_ sym: String) -> String {
      return "Give this site permission to access your \(sym)?"
    }
}
