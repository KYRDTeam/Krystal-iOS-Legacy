//
//  KrystalSolanaTransactionItemViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import UIKit

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
      return "Rate..."
    } else if isTokenTransferTransaction {
      let tx = transaction.details.tokensTransferTxs[0]
      let isTransferToOther = transaction.signer.first == tx.sourceOwner
      if isTransferToOther {
        return "To: \(tx.destinationOwner)"
      } else {
        return "From: \(tx.sourceOwner)"
      }
    } else if isSolTransferTransaction {
      let tx = transaction.details.solTransferTxs[0]
      let isTransferToOther = transaction.signer.first == tx.source
      if isTransferToOther {
        return "To: \(tx.destination)"
      } else {
        return "From: \(tx.source)"
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
  
  var isTransferToOther: Bool {
    if transaction.details.tokensTransferTxs.isEmpty {
      return false
    }
    return transaction.signer.first == transaction.details.tokensTransferTxs[0].sourceOwner
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
