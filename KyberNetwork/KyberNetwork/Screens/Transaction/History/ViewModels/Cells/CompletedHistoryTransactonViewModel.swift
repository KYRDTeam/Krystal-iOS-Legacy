//
//  CompletedHistoryTransactonViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation
import UIKit
import BigInt

class CompletedHistoryTransactonViewModel: TransactionHistoryItemViewModelProtocol {
  
  var fromIconSymbol: String {
    guard self.data.type == .swap || self.data.type == .earn || self.data.type == .withdraw else {
      return ""
    }
    
    if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
      return transaction.from.lowercased() == self.data.wallet
    } {
      return outTx.tokenSymbol
    }
     
    return KNGeneralProvider.shared.quoteToken
  }
  
  var toIconSymbol: String {
    guard self.data.type == .swap || self.data.type == .earn || self.data.type == .withdraw else {
      return ""
    }
    
    if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      return KNGeneralProvider.shared.quoteToken
    }
    
    if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      return inTx.tokenSymbol
    }
    return ""
  }
  
  func generateSwapAmountString() -> String {
    var result = ""
    let outTxs = self.data.tokenTransactions.filter { (transaction) -> Bool in
      return transaction.from.lowercased() == self.data.wallet
    }
    if !outTxs.isEmpty, let outTx = outTxs.first {

      var allValues: [BigInt] = []
      outTxs.forEach { item in
        let itemValue = BigInt(item.value) ?? BigInt(0)
        allValues.append(itemValue)
      }
      let valueBigInt = allValues.max() ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: Int(outTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(outTx.tokenSymbol) -> "
    } else if let sendEthTx = self.data.transacton.first {
      let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(KNGeneralProvider.shared.quoteToken) -> "
    }

    if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      let valueBigInt = BigInt(inTx.value) ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: Int(inTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(inTx.tokenSymbol)"
    }
    
    if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(KNGeneralProvider.shared.quoteToken)"
    }

    return result
  }

  var displayedAmountString: String {
    switch self.data.type {
    case .swap:
      if self.isError {
        return "--/--"
      }
      return self.generateSwapAmountString()
    case .withdraw:
      if self.isError {
        return "--/--"
      }
      return self.generateSwapAmountString()
    case .transferETH:
      if let sendEthTx = self.data.transacton.first {
        let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "- \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      }
      return ""
    case .receiveETH:
      if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "+ \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      } else if let receiveEthTx = self.data.transacton.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "+ \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      }
      return ""
    case .transferToken:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        let valueBigInt = BigInt(outTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: Int(outTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "- \(valueString) \(outTx.tokenSymbol)"
      }
      return ""
    case .receiveToken:
      if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(inTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: Int(inTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "+ \(valueString) \(inTx.tokenSymbol)"
      }
      return ""
    case .allowance:
      if let tx = self.data.transacton.first  {
        let address = tx.to
        if address == Constants.gasTokenAddress {
          return "CHI"
        } else if let token = KNSupportedTokenStorage.shared.getTokenWith(address: address) {
          return token.name
        }
      }
      return "Token"
    case .earn:
      if self.isError {
        return "--/--"
      }
      return self.generateSwapAmountString()
    case .contractInteraction:
      return "--/--"
    case .selfTransfer:
      if let sendEthTx = self.data.transacton.first {
        let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "- \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      }
      return ""
    case .createNFT:
      if self.isError {
        return "--/--"
      }
      if let tx = self.data.nftTransaction.first {
        return "Mint \(tx.tokenName)"
      }
      return "Mint NFT"
    case .transferNFT:
      if self.isError {
        return "--/--"
      }
      if let tx = self.data.nftTransaction.first {
        return "Transfer \(tx.tokenName)"
      }
      return "Transer NFT"
    case .receiveNFT:
      if self.isError {
        return "--/--"
      }
      if let tx = self.data.nftTransaction.first {
        return "Receive \(tx.tokenName)"
      }
      return "Receive NFT"
    case .claimReward:
      return "Claim Reward"
    case .multiSend:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        let valueBigInt = BigInt(outTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: Int(outTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "- \(valueString) \(outTx.tokenSymbol)"
      }
      return ""
    case .bridge:
      return ""
    }
  }

  var transactionDetailsString: String {
    switch self.data.type {
    case .swap:
      guard self.data.transacton.first?.isError != "1" else {
        return ""
      }
      var fromValue = BigInt.zero
      var toValue = BigInt.zero
      var fromSymbol = ""
      var toSymbol = ""
      var fromDecimal = 0
      var toDecimal = 0
      let outTxs = self.data.tokenTransactions.filter { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      }
      if !outTxs.isEmpty, let outTx = outTxs.first {
        var allValues: [BigInt] = []
        outTxs.forEach { item in
          let itemValue = BigInt(item.value) ?? BigInt(0)
          allValues.append(itemValue)
        }
        let valueBigInt = allValues.max() ?? BigInt(0)
        fromValue = valueBigInt
        fromSymbol = outTx.tokenSymbol
        fromDecimal = Int(outTx.tokenDecimal) ?? 0
      } else if let sendEthTx = self.data.transacton.first {
        let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
        fromValue = valueBigInt
        fromSymbol = KNGeneralProvider.shared.quoteToken
        fromDecimal = 18
      }

      if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(inTx.value) ?? BigInt(0)
        toValue = valueBigInt
        toSymbol = inTx.tokenSymbol
        toDecimal = Int(inTx.tokenDecimal) ?? 0
      }

      if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
        toValue = valueBigInt
        toSymbol = KNGeneralProvider.shared.quoteToken
        toDecimal = 18
      }
      guard !toSymbol.isEmpty, !fromSymbol.isEmpty else {
        return ""
      }
      let amountFrom = fromValue * BigInt(10).power(18) / BigInt(10).power(fromDecimal)
      let amountTo = toValue * BigInt(10).power(18) / BigInt(10).power(toDecimal)
      guard !amountFrom.isZero else {
        return ""
      }
      let rate = amountTo * BigInt(10).power(18) / amountFrom
      let rateString = rate.displayRate(decimals: 18)
      return "1 \(fromSymbol) = \(rateString) \(toSymbol)"
    case .withdraw:
      return ""
    case .transferETH:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        return "To: \(outTx.to)"
      }
      return ""
    case .receiveETH:
      if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      }) {
        return "From: \(receiveEthTx.from)"
      }
      return ""
    case .transferToken:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        return "To: \(outTx.to)"
      }
      return ""
    case .receiveToken:
      if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        return "From: \(inTx.from)"
      }
      return ""
    case .allowance:
      return self.data.transacton.first?.to ?? ""
    case .earn:
      return ""
    case .contractInteraction:
      return self.data.transacton.first?.to ?? ""
    case .selfTransfer:
      return ""
    case .createNFT:
      return ""
    case .transferNFT:
      return ""
    case .receiveNFT:
      if let tx = self.data.nftTransaction.first {
        return "From: \(tx.from)"
      }
      return ""
    case .claimReward:
      return "Claim reward"
    case .multiSend:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        return "To: \(outTx.to)"
      }
      return ""
    case .bridge:
      return ""
    }
  }
  
  var transactionTypeString: String {
    switch self.data.type {
    case .swap:
      return "SWAP"
    case .withdraw:
      return "WITHDRAWAL"
    case .transferETH:
      return "TRANSFER"
    case .receiveETH:
      return "RECEIVED"
    case .transferToken:
      return "TRANSFER"
    case .receiveToken:
      return "RECEIVED"
    case .allowance:
      return "APPROVAL"
    case .earn:
      return "SUPPLY"
    case .contractInteraction:
      return "CONTRACT INTERACT"
    case .selfTransfer:
      return "SELF"
    case .createNFT:
      return "MINT"
    case .transferNFT:
      return "TRANSFER"
    case .receiveNFT:
      return "RECEIVED"
    case .claimReward:
      return "CLAIM REWARD"
    case .multiSend:
      return "MULTISEND"
    case .bridge:
      return "BRIDGE"
    }
  }

  var isError: Bool {
    if let transaction = self.data.transacton.first {
      return transaction.isError != "0"
    } else if let internalTx = self.data.internalTransactions.first {
      return internalTx.isError != "0"
    } else {
      return false
    }
  }

  var transactionTypeImage: UIImage {
    switch self.data.type {
    case .swap:
      return UIImage()
    case .withdraw:
      return UIImage()
    case .transferETH:
      return Images.historyTransfer
    case .receiveETH:
      return Images.historyReceive
    case .transferToken:
      return Images.historyTransfer
    case .receiveToken:
      return Images.historyReceive
    case .allowance:
      return Images.historyApprove
    case .earn:
      return UIImage()
    case .contractInteraction:
      return Images.historyContractInteraction
    case .selfTransfer:
      return Images.historyTransfer
    case .createNFT:
      return Images.historyReceive
    case .transferNFT:
      return Images.historyTransfer
    case .receiveNFT:
      return Images.historyReceive
    case .claimReward:
      return Images.historyClaimReward
    case .multiSend:
      return Images.historyMultisend
    case .bridge:
      return Images.historyBridge
    }
  }

  var displayTime: String {
    return self.dateStringFromTimeStamp(self.data.timestamp)
  }

  func dateStringFromTimeStamp(_ ts: String) -> String {
    let date = Date(timeIntervalSince1970: Double(ts) ?? 0)
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: date)
  }
  
  let data: HistoryTransaction
  
  init(data: HistoryTransaction) {
    self.data = data
  }
}
