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
  
  let transaction: SolanaTransaction
  
  init(transaction: SolanaTransaction) {
    self.transaction = transaction
  }
}

extension KrystalSolanaTransactionItemViewModel {
  
  var interactProgram: String {
    return transaction.parsedInstruction.first?.programId ?? ""
  }
  
  var fromIconSymbol: String {
    if isSwapTransaction {
      return swapEvents.first!.symbol
    }
    return ""
  }
  
  var toIconSymbol: String {
    if isSwapTransaction {
      return swapEvents.last!.symbol
    }
    return ""
  }
  
  var transactionModelType: HistoryModelType {
    if isSwapTransaction {
      return .swap
    } else if isTokenTransferTransaction || isSolTransferTransaction {
      return .transferToken
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
    return swapEvents.count >= 2
  }
  
  var isTransferToOther: Bool {
    if isSwapTransaction {
      return false
    } else if isTokenTransferTransaction {
      return transaction.details.tokensTransferTxs.first?.sourceOwner == transaction.signer.first
    } else if isSolTransferTransaction {
      return transaction.details.solTransferTxs.first?.source == transaction.signer.first
    }
    return false
  }
  
  var displayedAmountString: String {
    if isSwapTransaction {
      let tx0 = swapEvents.first!
      let tx1 = swapEvents.last!
      let fromAmount = formattedAmount(amount: tx0.amount, decimals: tx0.decimals)
      let toAmount = formattedAmount(amount: tx1.amount, decimals: tx1.decimals)
      return String(format: "%@ %@ → %@ %@", fromAmount, tx0.symbol, toAmount, tx1.symbol)
    } else if isTokenTransferTransaction {
      let tx = transaction.details.tokensTransferTxs[0]
      let amountString = formattedAmount(amount: tx.amount, decimals: tx.token.decimals)
      let symbol = tx.token.symbol
      return isTransferToOther ? "-\(amountString) \(symbol)": "\(amountString) \(symbol)"
    } else if isSolTransferTransaction {
      let tx = transaction.details.solTransferTxs[0]
      let amountString = formattedAmount(amount: tx.amount, decimals: Constants.Tokens.Decimals.solana)
      return isTransferToOther
        ? "-\(amountString) \(Constants.Tokens.Symbol.solana)"
        : "\(amountString) \(Constants.Tokens.Symbol.solana)"
    }
    return "Application"
  }
  
  var transactionDetailsString: String {
    if isSwapTransaction {
      let tx0 = swapEvents.first!
      let tx1 = swapEvents.last!
      let formattedRate = formattedSwapRate(tx0: tx0, tx1: tx1)
      return "1 \(tx0.symbol) = \(formattedRate) \(tx1.symbol)"
    } else if isTokenTransferTransaction {
      let tx = transaction.details.tokensTransferTxs[0]
      if isTransferToOther {
        return String(format: "to_colon_x".toBeLocalised(), tx.destinationOwner)
      } else {
        return String(format: "from_colon_x".toBeLocalised(), tx.sourceOwner)
      }
    } else if isSolTransferTransaction {
      let tx = transaction.details.solTransferTxs[0]
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
  
  var swapEvents: [SolanaTransaction.Details.Event] {
    let unknownTransferTxs = transaction.details.unknownTransferTxs.flatMap(\.event)
    let raydiumTransferTxs = transaction.details.raydiumTxs.compactMap { $0.swap }.flatMap { $0.event }
    if !unknownTransferTxs.isEmpty {
      return unknownTransferTxs
    } else {
      return raydiumTransferTxs
    }
  }
  
  private func formattedSwapRate(tx0: SolanaTransaction.Details.Event, tx1: SolanaTransaction.Details.Event) -> String {
    let sourceAmountBigInt = BigInt(tx0.amount)
    let destAmountBigInt = BigInt(tx1.amount)
    
    let amountFrom = sourceAmountBigInt * BigInt(10).power(18) / BigInt(10).power(tx0.decimals)
    let amountTo = destAmountBigInt * BigInt(10).power(18) / BigInt(10).power(tx1.decimals)
    let rate = amountTo * BigInt(10).power(18) / amountFrom
    return rate.displayRate(decimals: 18)
  }
  
  private func formattedAmount(amountString: String, decimals: Int) -> String {
    let bigIntAmount = BigInt(amountString) ?? BigInt(0)
    return bigIntAmount.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: 6)
  }
  
  private func formattedAmount(amount: Double, decimals: Int) -> String {
    let bigIntAmount = BigInt(amount)
    return bigIntAmount.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: 6)
  }
}
