//
//  KNHistoryViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import Foundation
import UIKit

class KNHistoryViewModel {
  fileprivate(set) var tokens: [String] = []
  fileprivate(set) var currentWallet: KNWalletObject
  fileprivate(set) var filters: KNTransactionFilter!
  
  var tokenSymbols: [String] {
    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
      return EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols()
    }
    return EtherscanTransactionStorage.shared.getEtherscanToken().map { $0.symbol }
  }

  init(currentWallet: KNWalletObject) {
    self.currentWallet = currentWallet
    self.tokens = tokenSymbols
    self.filters = KNTransactionFilter(
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
      tokens: self.tokens
    )
  }

  func update(tokens: [String]) {
    self.tokens = tokens
    self.filters = KNTransactionFilter(
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
      tokens: tokens
    )
  }

  func updateCurrentWallet(_ currentWallet: KNWalletObject) {
    self.currentWallet = currentWallet
  }
//
//  var isRateMightChangeHidden: Bool {
//    return true
//  }
//
//  var transactionCollectionViewBottomPaddingConstraint: CGFloat {
//    return self.isRateMightChangeHidden ? 0.0 : 192.0
//  }

//  var tokensSymbol: [String] {
//    if !KNGeneralProvider.shared.currentChain.isSupportedHistoryAPI() {
//      return EtherscanTransactionStorage.shared.getInternalHistoryTokenSymbols()
//    }
//    return self.tokens
//  }

  var normalAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.white,
  ]

  var selectedAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
    NSAttributedString.Key.foregroundColor: UIColor.Kyber.enygold,
  ]

//  func updateFilters(_ filters: KNTransactionFilter) {
//    self.filters = filters
//  }

//  var isShowingQuickTutorial: Bool = false
//
//  var timeForLongPendingTx: Double {
//    return KNEnvironment.default == .ropsten ? 30.0 : 300
//  }
//
//  var isShowQuickTutorialForLongPendingTx: Bool {
//    return UserDefaults.standard.bool(forKey: Constants.kisShowQuickTutorialForLongPendingTx)
//  }
}
