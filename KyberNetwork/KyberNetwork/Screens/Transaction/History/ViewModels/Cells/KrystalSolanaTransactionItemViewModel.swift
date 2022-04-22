//
//  KrystalSolanaTransactionItemViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import UIKit
import BigInt

class KrystalSolanaTransactionItemViewModel: TransactionHistoryItemViewModelProtocol {
  
  let transaction: KrystalSolanaTransaction
  
  init(transaction: KrystalSolanaTransaction) {
    self.transaction = transaction
  }
}

extension KrystalSolanaTransactionItemViewModel {
  
  var interactProgram: String {
    return transaction.parsedInstruction.first?.programId ?? ""
  }
  
  var fromIconSymbol: String {
    if isSwapTransaction {
      return transferEvents[0].symbol
    }
    return ""
  }
  
  var toIconSymbol: String {
    if isSwapTransaction {
      return transferEvents[1].symbol
    }
    return ""
  }
  
  var transactionModelType: HistoryModelType {
    if isTokenTransferTransaction || isSolTransferTransaction {
      return .transferToken
    } else if isSwapTransaction {
      return .swap
    } else {
      return .contractInteraction
    }
  }
  
  var isTokenTransferTransaction: Bool {
    return !transaction.details.tokensTransferTxs.isEmpty
  }
  
  var isSolTransferTransaction: Bool {
    return !transaction.details.solTransferTxs.isEmpty
  }
  
  var isSwapTransaction: Bool {
    return transferEvents.count == 2
  }
  
  var displayedAmountString: String {
    if isSwapTransaction {
      let tx0 = transferEvents[0]
      let tx1 = transferEvents[1]
      return String(format: "%@ %@ -> %@ %@", tx0.formattedAmount, tx0.symbol, tx1.formattedAmount, tx1.symbol)
    } else if isTokenTransferTransaction {
      let tx = transaction.details.tokensTransferTxs[0]
      let amountString = tx.amountString
      let symbol = tx.token.symbol
      let isTransferToOther = transaction.signer.first == tx.sourceOwner
      return isTransferToOther ? "-\(amountString) \(symbol)" : "\(amountString) \(symbol)"
    } else if isSolTransferTransaction {
      let tx = transaction.details.solTransferTxs[0]
      let amountString = tx.amountString
      let isTransferToOther = transaction.signer.first == tx.source
      return isTransferToOther ? "-\(amountString) \(Constants.Tokens.Symbol.solana)" : "\(amountString) \(Constants.Tokens.Symbol.solana)"
    }
    return "--/--"
  }
  
  var transactionDetailsString: String {
    if isSwapTransaction {
      let tx0 = transferEvents[0]
      let tx1 = transferEvents[1]
      let formattedRate = formattedSwapRate(from: tx0.amount, to: tx1.amount, decimals: tx0.decimals)
      return "1 \(tx0.symbol) = \(formattedRate) \(tx1.symbol)"
    } else if isTokenTransferTransaction {
      let tx = transaction.details.tokensTransferTxs[0]
      let isTransferToOther = transaction.signer.first == tx.sourceOwner
      if isTransferToOther {
        return String(format: "to_colon_x".toBeLocalised(), tx.destinationOwner)
      } else {
        return String(format: "from_colon_x".toBeLocalised(), tx.sourceOwner)
      }
    } else if isSolTransferTransaction {
      let tx = transaction.details.solTransferTxs[0]
      let isTransferToOther = transaction.signer.first == tx.source
      if isTransferToOther {
        return String(format: "to_colon_x".toBeLocalised(), tx.destination)
      } else {
        return String(format: "from_colon_x".toBeLocalised(), tx.source)
      }
    } else {
      return interactProgram
    }
  }
  
  var transactionTypeString: String {
    return transactionModelType.displayString
  }
  
  var isError: Bool {
    return false
  }
  
  var transactionTypeImage: UIImage {
    return transactionModelType.displayIcon
  }
  
  var displayTime: String {
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: transaction.txDate)
  }
  
  var transferEvents: [KrystalSolanaTransaction.Event] {
    return transaction.details.unknownTransferTxs.flatMap(\.event)
      .filter { $0.type == "transfer" }
  }
  
  func formattedSwapRate(from: String, to: String, decimals: Int) -> String {
    let sourceAmountBigInt = BigInt(from) ?? BigInt(0)
    let destAmountBigInt = BigInt(to) ?? BigInt(0)
    
    let amountFrom = sourceAmountBigInt * BigInt(10).power(18) / BigInt(10).power(decimals)
    let amountTo = destAmountBigInt * BigInt(10).power(18) / BigInt(10).power(decimals)
    let rate = amountTo * BigInt(10).power(18) / amountFrom
    return rate.displayRate(decimals: 18)
  }
}

fileprivate extension KrystalSolanaTransaction.SolTransferTx {
  
  var amountString: String {
    let decimals = Constants.Tokens.Decimals.solana
    let amount = amount.doubleAmount(decimals: decimals)
    return amount.formattedAmount(decimals: decimals)
  }
  
}

fileprivate extension KrystalSolanaTransaction.TokenTransferTx {
  
  var amountString: String {
    let decimals = token.decimals
    let amount = amount.doubleAmount(decimals: decimals)
    return amount.formattedAmount(decimals: decimals)
  }
  
}

fileprivate extension KrystalSolanaTransaction.Event {
  
  var formattedAmount: String {
    return amount.doubleAmount(decimals: decimals).formattedAmount(decimals: decimals)
  }
  
}

fileprivate extension String {
  
  func toFormattedAmountString(decimals: Int) -> String {
    let amountBigInt = BigInt(self) ?? BigInt(0)
    let formattedValue = amountBigInt.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: 6)
    return formattedValue
  }
  
  func doubleAmount(decimals: Int) -> Double {
    return (Double(self) ?? 0) / pow(Double(10), Double(decimals))
  }
  
}

fileprivate extension Double {
  
  func formattedAmount(decimals: Int) -> String {
    return numberFormatter(decimals: decimals).string(from: NSNumber(value: self)) ?? ""
  }
  
  func numberFormatter(decimals: Int) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimals
    return formatter
  }
  
}
