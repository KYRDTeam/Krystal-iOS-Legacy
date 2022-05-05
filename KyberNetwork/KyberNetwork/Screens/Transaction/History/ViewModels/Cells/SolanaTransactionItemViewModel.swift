//
//  KrystalSolanaTransactionItemViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import UIKit
import BigInt

class SolanaTransactionItemViewModel: TransactionHistoryItemViewModelProtocol {
  
  let transaction: SolanaTransaction
  
  init(transaction: SolanaTransaction) {
    self.transaction = transaction
  }
}

extension SolanaTransactionItemViewModel {
  
  var interactProgram: String {
    return transaction.details.inputAccount.last?.account ?? ""
  }
  
  var fromIconSymbol: String {
    switch transaction.type {
    case .swap:
      return swapEvents.first?.symbol ?? ""
    default:
      return ""
    }
  }
  
  var toIconSymbol: String {
    switch transaction.type {
    case .swap:
      return swapEvents.last?.symbol ?? ""
    default:
      return ""
    }
  }
  
  var txType: HistoryModelType {
    switch transaction.type {
    case .swap:
      return .swap
    case .solTransfer, .splTransfer, .unknownTransfer:
      return transaction.isTransferToOther ? .transferToken : .receiveToken
    default:
      return .contractInteraction
    }
  }
  
  var displayedAmountString: String {
    switch transaction.type {
    case .swap:
      return tokenSwapAmountString
    case .splTransfer:
      return tokenTransferTxAmountString
    case .solTransfer:
      return solanaTransferTxAmountString
    case .unknownTransfer:
      return unknownTransferTxAmountString
    default:
      return Strings.application
    }
  }
  
  var transactionDetailsString: String {
    switch transaction.type {
    case .swap:
      return swapRateString
    case .splTransfer:
      return tokenTransferInfoString
    case .solTransfer:
      return solTransferString
    case .unknownTransfer:
      return unknownTxInfoString
    default:
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
    return transaction.swapEvents
  }
  
  private var solTransferString: String {
    guard let tx = transaction.details.solTransfers.first else { return "" }
    if transaction.isTransferToOther {
      return String(format: Strings.toColonX, tx.destination)
    } else {
      return String(format: Strings.fromColonX, tx.source)
    }
  }
  
  private var tokenTransferInfoString: String {
    guard let tx = transaction.details.tokenTransfers.first else { return "" }
    if transaction.isTransferToOther {
      return String(format: Strings.toColonX, tx.destinationOwner)
    } else {
      return String(format: Strings.fromColonX, tx.sourceOwner)
    }
  }
  
  private var unknownTxInfoString: String {
    guard let tx = transaction.details.unknownTransfers.first?.event.first else { return "" }
    if transaction.isTransferToOther {
      return String(format: Strings.toColonX, tx.destination ?? "")
    } else {
      return String(format: Strings.fromColonX, tx.source ?? "")
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
    guard let tx = transaction.details.tokenTransfers.first else { return "" }
    let amountString = formattedAmount(amount: tx.amount, decimals: tx.token.decimals)
    let symbol = tx.token.symbol
    return transaction.isTransferToOther ? "-\(amountString) \(symbol)": "\(amountString) \(symbol)"
  }
  
  private var solanaTransferTxAmountString: String {
    guard let tx = transaction.details.solTransfers.first else { return "" }
    let quoteToken = KNGeneralProvider.shared.currentChain.quoteTokenObject()
    let amountString = formattedAmount(amount: tx.amount, decimals: quoteToken.decimals)
    return transaction.isTransferToOther
      ? "-\(amountString) \(quoteToken.symbol)"
      : "\(amountString) \(quoteToken.symbol)"
  }
  
  private var unknownTransferTxAmountString: String {
    guard let tx = transaction.details.unknownTransfers.first?.event.first else { return "" }
    let amountString = formattedAmount(amount: tx.amount, decimals: tx.decimals)
    let symbol = tx.symbol
    return transaction.isTransferToOther ? "-\(amountString) \(symbol)": "\(amountString) \(symbol)"
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
