//
//  InternalHistoryTransaction+TransactionHistoryItem.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

extension InternalHistoryTransaction: TransactionHistoryItem {
  
  var txDate: Date {
    return time
  }
  
  var txHash: String {
    return hash
  }
  
  func match(filter: KNTransactionFilter, allTokens: [String]) -> Bool {
    var isMatchingConditions = true

    let matchedTransfer = (type == .transferETH || type == .transferNFT || type == .transferToken) && filter.isSend
    let matchedReceive = (type == .receiveETH || type == .receiveNFT || type == .receiveToken) && filter.isReceive
    let matchedSwap = (type == .swap) && filter.isSwap
    let matchedAppprove = (type == .allowance) && filter.isApprove
    let matchedSupply = (type == .earn) && filter.isTrade
    let matchedWithdraw = (type == .withdraw) && filter.isWithdraw
    let matchedClaimReward = (type == .claimReward) && filter.isClaimReward
    let matchedContractInteraction = (type == .contractInteraction) && filter.isContractInteraction
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward

    isMatchingConditions = isMatchingConditions && matchedType
    
    let txTokens = [fromSymbol, toSymbol].compactMap { $0 }
    
    if txTokens.isEmpty {
      isMatchingConditions = isMatchingConditions && filter.tokens.count == allTokens.count
    } else {
      isMatchingConditions = isMatchingConditions && filter.tokens.containsElementsOf(other: txTokens)
    }
    return isMatchingConditions
  }
  
  func toViewModel() -> TransactionHistoryItemViewModelProtocol {
    return PendingInternalHistoryTransactonViewModel(transaction: self)
  }
  
}
