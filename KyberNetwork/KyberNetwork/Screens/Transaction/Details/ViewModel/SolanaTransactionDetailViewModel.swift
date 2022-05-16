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
    case .swap(let swapData):
      return getSwapAmountString(swapData: swapData)
    case .transfer(let txData):
      return getTransferAmountString(txData: txData)
    default:
      return "--"
    }
  }
  
  var displayFromAddress: String {
    return transaction.userAddress
  }
  
  var displayToAddress: String {
    switch transaction.type {
    case .transfer(let txData):
      return transaction.isTransferToOther ? txData.destinationAddress : txData.sourceAddress
    case .swap(let swapData):
      return swapData.programId
    case .other(let programId):
      return programId
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
  
  var fromFieldTitle: String {
    return Strings.wallet
  }
  
  var toFieldTitle: String {
    switch transaction.type {
    case .transfer:
      return transaction.isTransferToOther ? Strings.to : Strings.from
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
    case .transfer:
      return transaction.isTransferToOther ? .transferToken : .receiveToken
    default:
      return .contractInteraction
    }
  }
  
  private func getTransferAmountString(txData: SolanaTransaction.TransferData) -> String {
    let amountString = formattedAmount(amount: txData.amount, decimals: txData.decimals)
    return transaction.isTransferToOther
      ? "-\(amountString) \(txData.symbol)"
      : "\(amountString) \(txData.symbol)"
  }
  
  private func getSwapAmountString(swapData: SolanaTransaction.SwapData) -> String {
    let fromAmount = formattedAmount(amount: swapData.sourceAmount, decimals: swapData.sourceDecimals)
    let toAmount = formattedAmount(amount: swapData.destinationAmount, decimals: swapData.destinationDecimals)
    return String(format: "%@ %@ → %@ %@", fromAmount, swapData.sourceSymbol, toAmount, swapData.destinationSymbol)
  }
  
  private func formattedAmount(amount: Double, decimals: Int) -> String {
    let bigIntAmount = BigInt(amount)
    return bigIntAmount.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: 6)
  }
}
