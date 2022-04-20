//
//  CompletedKrystalHistoryTransactionViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import UIKit

class CompletedKrystalHistoryTransactionViewModel: AbstractHistoryTransactionViewModel {

  var fromIconSymbol: String {
    if self.historyItem.isSwapTokenType {
      return self.historyItem.extraData?.sendToken?.symbol ?? ""
    } else if historyItem.type == "Received" {
      return ""
    } else if historyItem.type == "Transfer" {
      return ""
    } else if historyItem.type == "Approval" {
      return ""
    } else {
      return ""
    }
  }

  var toIconSymbol: String {
    if self.historyItem.isSwapTokenType {
      return self.historyItem.extraData?.receiveToken?.symbol ?? ""
    } else if historyItem.type == "Received" {
      return ""
    } else if historyItem.type == "Transfer" {
      return ""
    } else if historyItem.type == "Approval" {
      return ""
    } else {
      return ""
    }
  }
  
  var displayedAmountString: String {
    if self.historyItem.isSwapTokenType {
      if self.isError {
        return "--/--"
      }
      var result = ""
      let sendValueBigInt = BigInt(self.historyItem.extraData?.sendValue ?? "") ?? BigInt(0)
      let sendValueString = sendValueBigInt.string(decimals: self.historyItem.extraData?.sendToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(sendValueString) \(self.historyItem.extraData?.sendToken?.symbol ?? "") -> "
      let valueBigInt = BigInt(self.historyItem.extraData?.receiveValue ?? "") ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: self.historyItem.extraData?.receiveToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(self.historyItem.extraData?.receiveToken?.symbol ?? "")"
      
      return result
    } else if historyItem.type == "Received" {
      let valueBigInt = BigInt(self.historyItem.extraData?.receiveValue ?? "") ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: self.historyItem.extraData?.receiveToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      return "+ \(valueString) \(self.historyItem.extraData?.receiveToken?.symbol ?? "")"
    } else if historyItem.type == "Transfer" {
      let valueBigInt = BigInt(self.historyItem.extraData?.sendValue ?? "") ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: self.historyItem.extraData?.sendToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      return "- \(valueString) \(self.historyItem.extraData?.sendToken?.symbol ?? "")"
    } else if historyItem.type == "Approval" {
      return self.historyItem.extraData?.token?.name ?? ""
    } else if historyItem.type == "ClaimReward", let decimal = self.historyItem.extraData?.receiveToken?.decimals, let symbol = self.historyItem.extraData?.receiveToken?.symbol {
      guard let receiveValueString = self.historyItem.extraData?.receiveValue, let receiveValue = BigInt(receiveValueString) else { return "" }
      return "+" + " " + receiveValue.string(decimals: decimal, minFractionDigits: 0, maxFractionDigits: 4) + " \(symbol)"
    } else {
      return "--/--"
    }
  }
  
  var transactionDetailsString: String {
    if self.historyItem.isSwapTokenType {
      if self.isError {
        return ""
      }
      let sendValueBigInt = BigInt(self.historyItem.extraData?.sendValue ?? "") ?? BigInt(0)
      let valueBigInt = BigInt(self.historyItem.extraData?.receiveValue ?? "") ?? BigInt(0)
      guard !sendValueBigInt.isZero else {
        return ""
      }
      let amountFrom = sendValueBigInt * BigInt(10).power(18) / BigInt(10).power(self.historyItem.extraData?.sendToken?.decimals ?? 18)
      let amountTo = valueBigInt * BigInt(10).power(18) / BigInt(10).power(self.historyItem.extraData?.receiveToken?.decimals ?? 18)
      let rate = amountTo * BigInt(10).power(18) / amountFrom
      let rateString = rate.displayRate(decimals: 18)
      return "1 \(self.historyItem.extraData?.sendToken?.symbol ?? "") = \(rateString) \(self.historyItem.extraData?.receiveToken?.symbol ?? "")"
    } else if historyItem.type == "Received" {
      return "From: \(self.historyItem.from)"
    } else if historyItem.type == "Transfer" {
      return "To: \(self.historyItem.to)"
    } else if historyItem.type == "Approval" {
      return self.historyItem.to
    } else {
      return self.historyItem.to
    }
  }

  var transactionTypeString: String {
    if self.historyItem.type == "Swap" {
      return "SWAP"
    } else if historyItem.type == "Received" {
      return "RECEIVED"
    } else if historyItem.type == "Transfer" {
      return "TRANSFER"
    } else if historyItem.type == "Approval" {
      return "APPROVAL"
    } else if self.historyItem.type == "Supply" {
      return "SUPPLY"
    } else if self.historyItem.type == "Withdraw" {
      return "WITHDRAW"
    } else if self.historyItem.type == "ClaimReward" {
      return "CLAIM REWARD"
    } else {
      return "CONTRACT INTERACTION"
    }
  }
  
  var isError: Bool {
    return self.historyItem.status != "success"
  }
  
  var transactionTypeImage: UIImage {
    if self.historyItem.isSwapTokenType {
      return UIImage()
    } else if historyItem.type == "Received" {
      return UIImage(named: "history_receive_icon")!
    } else if historyItem.type == "Transfer" {
      return UIImage(named: "history_send_icon")!
    } else if historyItem.type == "Approval" {
      return UIImage(named: "history_approve_icon")!
    } else if historyItem.type == "ClaimReward" {
      return UIImage(named: "history_claim_reward_icon")!
    } else {
      return UIImage(named: "history_contract_interaction_icon")!
    }
  }

  var displayTime: String {
    let date = Date(timeIntervalSince1970: Double(self.historyItem.timestamp))
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: date)
  }
  
  let historyItem: KrystalHistoryTransaction
  
  init(item: KrystalHistoryTransaction) {
    self.historyItem = item
  }
}
