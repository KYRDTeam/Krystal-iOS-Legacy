//
//  SolanaTransactionDetailViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation
import UIKit
import BigInt

class SolanaTransactionDetailViewModel: TransactionDetailsViewModel {
  let transaction: SolanaTransaction
  
  let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM dd yyyy, HH:mm:ss ZZZZ"
    return formatter
  }()
  
  init(transaction: SolanaTransaction) {
    self.transaction = transaction
  }
  
  var isError: Bool {
    return transaction.status.lowercased() != "success"
  }
  
  var displayTxStatus: String {
    return transaction.status
  }
  
  var displayTxIcon: UIImage? {
    return isError ? UIImage(named: "warning_red_icon") : nil
  }
  
  var displayTxStatusColor: UIColor {
    return isError ? UIColor(red: 255, green: 110, blue: 64) : UIColor.Kyber.SWGreen
  }
  
  var displayTxTypeString: String {
    return txType.displayString
  }
  
  var displayDateString: String {
    return dateFormatter.string(from: transaction.txDate)
  }
  
  var displayAmountString: String {
    if isSwapTransaction {
      return tokenSwapAmountString
    } else if isTokenTransferTransaction {
      return tokenTransferTxAmountString
    } else if isSolTransferTransaction {
      return solanaTransferTxAmountString
    }
    return "Application"
  }
  
  var displayFromAddress: String {
    if isSwapTransaction {
      return transaction.signer.first ?? ""
    } else if isTokenTransferTransaction {
      guard !transaction.details.tokensTransferTxs.isEmpty else { return "" }
      return transaction.details.tokensTransferTxs[0].sourceOwner
    } else if isSolTransferTransaction {
      guard !transaction.details.solTransferTxs.isEmpty else { return "" }
      return transaction.details.solTransferTxs[0].source
    }
    return ""
  }
  
  var displayToAddress: String {
    if isSwapTransaction {
      return "" // TODO: Update use input account
    } else if isTokenTransferTransaction {
      guard !transaction.details.tokensTransferTxs.isEmpty else { return "" }
      return transaction.details.tokensTransferTxs[0].destinationOwner
    } else if isSolTransferTransaction {
      guard !transaction.details.solTransferTxs.isEmpty else { return "" }
      return transaction.details.solTransferTxs[0].destination
    }
    return "" // TODO: Update use input account
  }
  
  var displayGasFee: String {
    let feeBigInt = BigInt(transaction.fee)
    return feeBigInt.string(decimals: Constants.Tokens.Decimals.solana, minFractionDigits: 0, maxFractionDigits: 6) + " " + Constants.Tokens.Symbol.solana
  }
  
  var displayHash: String {
    return transaction.txHash
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
  
  var fromFieldTitle: String {
    if isTokenTransferTransaction || isSolTransferTransaction {
      if !isTransferToOther {
        return "From Wallet".toBeLocalised()
      }
    }
    return "Wallet".toBeLocalised()
  }
  
  var toFieldTitle: String {
    if isTokenTransferTransaction || isSolTransferTransaction {
      return "To Wallet".toBeLocalised()
    }
    return "Application".toBeLocalised()
  }
  
  var transactionTypeImage: UIImage {
    return txType.displayIcon
  }
  
  var transactionTypeString: String {
    return txType.displayString
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
  
  var swapEvents: [SolanaTransaction.Details.Event] {
    let unknownTransferTxs = transaction.details.unknownTransferTxs.flatMap(\.event)
    let raydiumTransferTxs = transaction.details.raydiumTxs.compactMap { $0.swap }.flatMap { $0.event }
    if !unknownTransferTxs.isEmpty {
      return unknownTransferTxs
    } else {
      return raydiumTransferTxs
    }
  }
  
  var interactProgram: String {
    return transaction.details.inputAccount.last?.account ?? ""
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
    let amountString = formattedAmount(amount: tx.amount, decimals: Constants.Tokens.Decimals.solana)
    return isTransferToOther
      ? "-\(amountString) \(Constants.Tokens.Symbol.solana)"
      : "\(amountString) \(Constants.Tokens.Symbol.solana)"
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
