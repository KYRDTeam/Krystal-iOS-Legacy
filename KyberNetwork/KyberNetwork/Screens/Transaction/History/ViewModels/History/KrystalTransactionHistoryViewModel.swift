//
//  KrystalTransactionHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation

class KrystalTransactionHistoryViewModel: BaseTransactionHistoryViewModel {
  override var isTransactionActionEnabled: Bool {
    return false
  }
  
  override init(currentWallet: KNWalletObject) {
    super.init(currentWallet: currentWallet)
    let allEtherscanTokens = EtherscanTransactionStorage.shared.getEtherscanToken().map { $0.symbol }
    self.allTokens = allEtherscanTokens
    self.filter = KNTransactionFilter(
      from: nil,
      to: nil,
      isSend: true,
      isReceive: true,
      isSwap: true,
      isApprove: true,
      isWithdraw: true,
      isTrade: true,
      isContractInteraction: true,
      isClaimReward: true,
      tokens: allEtherscanTokens
    )
  }
  
  override func fetchAllTransactions() -> [TransactionHistoryItem] {
    return EtherscanTransactionStorage.shared.getKrystalTransaction()
  }
  
}

extension KrystalHistoryTransaction: TransactionHistoryItem {
  
  var txDate: Date {
    return date
  }
  
  func match(filter: KNTransactionFilter, allTokens: [String]) -> Bool {
    var isMatchingConditions = true
    
    let from: Date = filter.from ?? Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    let to: Date = filter.to ?? Date().addingTimeInterval(24.0 * 60.0 * 60.0)
    
    isMatchingConditions = isMatchingConditions && date >= from.startDate()
    isMatchingConditions = isMatchingConditions && date < to.endDate()
    
    let matchedTransfer = (type == "Transfer") && filter.isSend
    let matchedReceive = (type == "Received") && filter.isReceive
    let matchedSwap = (type == "Swap") && filter.isSwap
    let matchedAppprove = (type == "Approval") && filter.isApprove
    let matchedSupply = (type == "Supply") && filter.isTrade
    let matchedWithdraw = (type == "Withdraw") && filter.isWithdraw
    let matchedClaimReward = (type == "ClaimReward") && filter.isClaimReward
    let matchedContractInteraction = (type == "" || type == "ContractInteration") && filter.isContractInteraction
    
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedContractInteraction || matchedSupply || matchedWithdraw || matchedClaimReward

    isMatchingConditions = isMatchingConditions && matchedType
        
    let txTokens = [
      extraData?.token?.symbol,
      extraData?.sendToken?.symbol,
      extraData?.receiveToken?.symbol
    ].compactMap { $0 }
    
    let isFilteringAllTokens = filter.tokens.count == allTokens.count
    
    if txTokens.isEmpty {
      // True when filter all tokens
      isMatchingConditions = isMatchingConditions && isFilteringAllTokens
    } else {
      isMatchingConditions = isMatchingConditions && (filter.tokens.isEmpty || filter.tokens.containsElementsOf(other: txTokens))
    }
    
    return isMatchingConditions
  }
  
  func toViewModel() -> TransactionHistoryItemViewModelProtocol {
    return CompletedKrystalHistoryTransactionViewModel(item: self)
  }
  
}
