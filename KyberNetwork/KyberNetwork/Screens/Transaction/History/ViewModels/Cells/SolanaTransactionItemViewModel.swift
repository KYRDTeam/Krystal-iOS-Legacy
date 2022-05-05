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
  
  var fromIconSymbol: String {
    switch transaction.type {
    case .swap(let data):
      return data.sourceSymbol
    default:
      return ""
    }
  }
  
  var toIconSymbol: String {
    switch transaction.type {
    case .swap(let data):
      return data.destinationSymbol
    default:
      return ""
    }
  }
  
  var txType: HistoryModelType {
    switch transaction.type {
    case .swap:
      return .swap
    case .transfer:
      return transaction.isTransferToOther ? .transferToken : .receiveToken
    default:
      return .contractInteraction
    }
  }
  
  var displayedAmountString: String {
    switch transaction.type {
    case .swap(let swapData):
      return getSwapAmountString(swapData: swapData)
    case .transfer(let txData):
      return getTransferAmountString(txData: txData)
    default:
      return Strings.application
    }
  }
  
  var transactionDetailsString: String {
    switch transaction.type {
    case .swap(let data):
      let formattedRate = getSwapRateString(swapData: data)
      return "1 \(data.sourceSymbol) = \(formattedRate) \(data.destinationSymbol)"
    case .transfer(let data):
      return getTransferDescription(txData: data)
    case .other(let programId):
      return programId
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
  
  private func getSwapAmountString(swapData: SolanaTransaction.SwapData) -> String {
    let fromAmount = formattedAmount(amount: swapData.sourceAmount, decimals: swapData.sourceDecimals)
    let toAmount = formattedAmount(amount: swapData.destinationAmount, decimals: swapData.destinationDecimals)
    return String(format: "%@ %@ → %@ %@", fromAmount, swapData.sourceSymbol, toAmount, swapData.destinationSymbol)
  }
  
  private func getSwapRateString(swapData: SolanaTransaction.SwapData) -> String {
    let sourceAmountBigInt = BigInt(swapData.sourceAmount)
    let destAmountBigInt = BigInt(swapData.destinationAmount)
    
    let amountFrom = sourceAmountBigInt * BigInt(10).power(18) / BigInt(10).power(swapData.sourceDecimals)
    let amountTo = destAmountBigInt * BigInt(10).power(18) / BigInt(10).power(swapData.destinationDecimals)
    let rate = amountTo * BigInt(10).power(18) / amountFrom
    return rate.displayRate(decimals: 18)
  }
  
  private func getTransferAmountString(txData: SolanaTransaction.TransferData) -> String {
    let amountString = formattedAmount(amount: txData.amount, decimals: txData.decimals)
    let symbol = txData.symbol
    return transaction.isTransferToOther ? "-\(amountString) \(symbol)": "\(amountString) \(symbol)"
  }
  
  private func getTransferDescription(txData: SolanaTransaction.TransferData) -> String {
    if transaction.isTransferToOther {
      return String(format: Strings.toColonX, txData.destinationAddress)
    } else {
      return String(format: Strings.fromColonX, txData.sourceAddress)
    }
  }
  
  private func formattedAmount(amount: Double, decimals: Int) -> String {
    let bigIntAmount = BigInt(amount)
    return bigIntAmount.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: 6)
  }
}
