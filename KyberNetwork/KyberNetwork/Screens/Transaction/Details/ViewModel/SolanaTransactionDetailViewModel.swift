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
    return isError ? Images.warningRedIcon : nil
  }
  
  var displayTxStatusColor: UIColor {
    return isError ? UIColor.Kyber.errorText : UIColor.Kyber.SWGreen
  }
  
  var displayTxTypeString: String {
    return txType.displayString
  }
  
  var displayDateString: String {
    return dateFormatter.string(from: transaction.txDate)
  }
  
  var displayAmountString: String {
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
      return "--"
    }
  }
  
  var displayFromAddress: String {
    switch transaction.type {
    case .swap:
      return transaction.details.inputAccount.first?.account ?? ""
    case .splTransfer:
      return transaction.details.tokenTransfers.first?.sourceOwner ?? ""
    case .solTransfer:
      return transaction.details.solTransfers.first?.source ?? ""
    default:
      return transaction.details.inputAccount.first?.account ?? ""
    }
  }
  
  var displayToAddress: String {
    switch transaction.type {
    case .splTransfer:
      return transaction.details.tokenTransfers.first?.destinationOwner ?? ""
    case .solTransfer:
      return transaction.details.solTransfers.first?.destination ?? ""
    default:
      return interactApplication
    }
  }
  
  var displayGasFee: String {
    let feeBigInt = BigInt(transaction.fee)
    let quoteToken = KNGeneralProvider.shared.currentChain.quoteTokenObject()
    return feeBigInt.string(decimals: quoteToken.decimals, minFractionDigits: 0, maxFractionDigits: 6) + " " + quoteToken.symbol
  }
  
  var displayHash: String {
    return transaction.txHash
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
  
  
  var fromFieldTitle: String {
    switch transaction.type {
    case .solTransfer, .splTransfer:
      return transaction.isTransferToOther ? Strings.wallet : Strings.fromWallet
    default:
      return Strings.wallet
    }
  }
  
  var toFieldTitle: String {
    switch transaction.type {
    case .solTransfer, .splTransfer:
      return Strings.toWallet
    default:
      return Strings.application
    }
  }
  
  var transactionTypeImage: UIImage {
    return txType.displayIcon
  }
  
  var transactionTypeString: String {
    return txType.displayString
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
  
  var swapEvents: [SolanaTransaction.Details.Event] {
    return transaction.swapEvents
  }
  
  var interactApplication: String {
    return transaction.details.inputAccount.last?.account ?? ""
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
