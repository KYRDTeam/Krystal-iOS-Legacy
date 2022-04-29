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
    return transaction.details.inputAccount.last?.account ?? ""
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
  
  var txType: HistoryModelType {
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
      return tokenSwapAmountString
    } else if isTokenTransferTransaction {
      return tokenTransferTxAmountString
    } else if isSolTransferTransaction {
      return solanaTransferTxAmountString
    }
    return "Application"
  }
  
  var transactionDetailsString: String {
    if isSwapTransaction {
      return swapRateString
    } else if isTokenTransferTransaction {
      return tokenTransferInfoString
    } else if isSolTransferTransaction {
      return solTransferString
    } else {
      return interactProgram
    }
  }
  
  var isError: Bool {
    return transaction.status.lowercased() != "success"
  }
  
  var transactionTypeImage: UIImage {
    return txType.displayIcon
  }
  
  var displayTime: String {
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: transaction.txDate)
  }
  
  var transactionTypeString: String {
    return txType.displayString
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
  
  private var solTransferString: String {
    guard !transaction.details.solTransferTxs.isEmpty else { return "" }
    let tx = transaction.details.solTransferTxs[0]
    if isTransferToOther {
      return String(format: "to_colon_x".toBeLocalised(), tx.destination)
    } else {
      return String(format: "from_colon_x".toBeLocalised(), tx.source)
    }
  }
  
  private var tokenTransferInfoString: String {
    guard !transaction.details.tokensTransferTxs.isEmpty else { return "" }
    let tx = transaction.details.tokensTransferTxs[0]
    if isTransferToOther {
      return String(format: "to_colon_x".toBeLocalised(), tx.destinationOwner)
    } else {
      return String(format: "from_colon_x".toBeLocalised(), tx.sourceOwner)
    }
  }
  
  private var swapRateString: String {
    guard swapEvents.count > 1 else { return "" }
    let tx0 = swapEvents.first!
    let tx1 = swapEvents.last!
    let formattedRate = formattedSwapRate(tx0: tx0, tx1: tx1)
    return "1 \(tx0.symbol) = \(formattedRate) \(tx1.symbol)"
  }
  
  private var tokenSwapAmountString: String {
    guard swapEvents.count > 1 else { return "" }
    let tx0 = swapEvents.first!
    let tx1 = swapEvents.last!
    let fromAmount = formattedAmount(amount: tx0.amount, decimals: tx0.decimals)
    let toAmount = formattedAmount(amount: tx1.amount, decimals: tx1.decimals)
    return String(format: "%@ %@ → %@ %@", fromAmount, tx0.symbol, toAmount, tx1.symbol)
  }
  
  private var tokenTransferTxAmountString: String {
    guard !transaction.details.tokensTransferTxs.isEmpty else { return "" }
    let tx = transaction.details.tokensTransferTxs[0]
    let amountString = formattedAmount(amount: tx.amount, decimals: tx.token.decimals)
    let symbol = tx.token.symbol
    return isTransferToOther ? "-\(amountString) \(symbol)": "\(amountString) \(symbol)"
  }
  
  private var solanaTransferTxAmountString: String {
    guard !transaction.details.solTransferTxs.isEmpty else { return "" }
    let tx = transaction.details.solTransferTxs[0]
    let quoteToken = KNGeneralProvider.shared.currentChain.quoteTokenObject()
    let amountString = formattedAmount(amount: tx.amount, decimals: quoteToken.decimals)
    return isTransferToOther
      ? "-\(amountString) \(quoteToken.symbol)"
      : "\(amountString) \(quoteToken.symbol)"
  }
  
  private func formattedSwapRate(tx0: SolanaTransaction.Details.Event, tx1: SolanaTransaction.Details.Event) -> String {
    let sourceAmountBigInt = BigInt(tx0.amount)
    let destAmountBigInt = BigInt(tx1.amount)
    
    let amountFrom = sourceAmountBigInt * BigInt(10).power(18) / BigInt(10).power(tx0.decimals)
    let amountTo = destAmountBigInt * BigInt(10).power(18) / BigInt(10).power(tx1.decimals)
    let rate = amountTo * BigInt(10).power(18) / amountFrom
    return rate.displayRate(decimals: 18)
  }
  
  private func formattedAmount(amount: Double, decimals: Int) -> String {
    let bigIntAmount = BigInt(amount)
    return bigIntAmount.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: 6)
  }
}
