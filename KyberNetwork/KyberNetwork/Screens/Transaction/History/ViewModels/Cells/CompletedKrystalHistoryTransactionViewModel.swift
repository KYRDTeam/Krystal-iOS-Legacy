//
//  CompletedKrystalHistoryTransactionViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import UIKit
import BigInt

class CompletedKrystalHistoryTransactionViewModel: TransactionHistoryItemViewModelProtocol {
  
  var transactionType: TransactionHistoryItemType {
    return TransactionHistoryItemType(rawValue: historyItem.type) ?? .contractInteraction
  }
  
  var fromIconSymbol: String {
    switch transactionType {
    case .swap, .supply, .withdraw:
      return self.historyItem.extraData?.sendToken?.symbol ?? ""
    default:
      return ""
    }
  }
  
  var toIconSymbol: String {
    switch transactionType {
    case .swap, .supply, .withdraw:
      return self.historyItem.extraData?.receiveToken?.symbol ?? ""
    default:
      return ""
    }
  }
  
  var displayedAmountString: String {
    let defaultAmountString = "--/--"
    switch transactionType {
    case .swap, .supply, .withdraw:
      if self.isError {
        return defaultAmountString
      }
      var result = ""
      let sendValueBigInt = BigInt(self.historyItem.extraData?.sendValue ?? "") ?? BigInt(0)
      let sendValueString = sendValueBigInt.string(decimals: self.historyItem.extraData?.sendToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(sendValueString) \(self.historyItem.extraData?.sendToken?.symbol ?? "") → "
      let valueBigInt = BigInt(self.historyItem.extraData?.receiveValue ?? "") ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: self.historyItem.extraData?.receiveToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(self.historyItem.extraData?.receiveToken?.symbol ?? "")"
      
      return result
    case .transfer:
      let valueBigInt = BigInt(self.historyItem.extraData?.sendValue ?? "") ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: self.historyItem.extraData?.sendToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      return "- \(valueString) \(self.historyItem.extraData?.sendToken?.symbol ?? "")"
    case .receive:
      let valueBigInt = BigInt(self.historyItem.extraData?.receiveValue ?? "") ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: self.historyItem.extraData?.receiveToken?.decimals ?? 18, minFractionDigits: 0, maxFractionDigits: 6)
      return "+ \(valueString) \(self.historyItem.extraData?.receiveToken?.symbol ?? "")"
    case .approval:
      return self.historyItem.extraData?.token?.name ?? ""
    case .claimReward:
      if let decimal = self.historyItem.extraData?.receiveToken?.decimals, let symbol = self.historyItem.extraData?.receiveToken?.symbol {
        guard let receiveValueString = self.historyItem.extraData?.receiveValue, let receiveValue = BigInt(receiveValueString) else { return "" }
        return "+" + " " + receiveValue.string(decimals: decimal, minFractionDigits: 0, maxFractionDigits: 4) + " \(symbol)"
      } else {
        return defaultAmountString
      }
    case .bridge:
      guard !isError else {
        return "--"
      }
      guard let from = historyItem.extraData?.from, let to = historyItem.extraData?.to else {
        return defaultAmountString
      }
      let fromAmountString = from.amount.string(decimals: from.decimals, minFractionDigits: 0, maxFractionDigits: 5)
      let toAmountString = to.amount.string(decimals: to.decimals, minFractionDigits: 0, maxFractionDigits: 5)
      return "\(fromAmountString) \(from.token) → \(toAmountString) \(to.token)"
    case .contractInteraction:
      return defaultAmountString
    case .multiSend, .multiReceive:
      return "\(historyItem.extraData?.txns?.count ?? 0) transfers"
    }
  }
  
  var transactionDetailsString: String {
    switch transactionType {
    case .swap, .supply, .withdraw:
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
    case .transfer:
      return "To: \(self.historyItem.to)"
    case .receive:
      return "From: \(self.historyItem.from)"
    case .bridge:
      guard !isError else {
        return historyItem.txHash
      }
      guard let from = historyItem.extraData?.from, let to = historyItem.extraData?.to else {
        return ""
      }
      let srcChainName = getChain(chainID: from.chainId)?.chainName() ?? ""
      let destChainName = getChain(chainID: to.chainId)?.chainName() ?? ""
      return "\(srcChainName) → \(destChainName)"
    default:
      return self.historyItem.to
    }
  }
  
  var transactionTypeString: String {
    switch transactionType {
    case .swap:
      return Strings.swap.uppercased()
    case .receive:
      return Strings.receive.uppercased()
    case .transfer:
      return Strings.transfer.uppercased()
    case .approval:
      return Strings.approval.uppercased()
    case .contractInteraction:
      return Strings.contractExecution.uppercased()
    case .claimReward:
      return Strings.claimReward.uppercased()
    case .bridge:
      return Strings.bridge.uppercased()
    case .multiSend:
      return Strings.multiSend.uppercased()
    case .multiReceive:
      return Strings.multiReceive.uppercased()
    default:
      return Strings.contractExecution.uppercased()
    }
  }
  
  var isError: Bool {
    switch transactionType {
    case .bridge:
      return historyItem.status.isEmpty || historyItem.extraData?.crosschainStatus?.isEmpty ?? true
    default:
      return historyItem.status != "success"
    }
    
  }
  
  var transactionTypeImage: UIImage {
    switch transactionType {
    case .swap, .supply, .withdraw:
      return UIImage()
    case .receive:
      return Images.historyReceive
    case .transfer:
      return Images.historyTransfer
    case .approval:
      return Images.historyApprove
    case .claimReward:
      return Images.historyClaimReward
    case .bridge:
      return Images.historyBridge
    case .multiSend, .multiReceive:
      return Images.historyMultisend
    default:
      return Images.historyContractInteraction
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
  
  private func getChain(chainID: String?) -> ChainType? {
    guard let chainID = chainID else {
      return nil
    }

    return ChainType.getAllChain().first { chain in
      chain.customRPC().chainID == Int(chainID)
    }
  }
}
