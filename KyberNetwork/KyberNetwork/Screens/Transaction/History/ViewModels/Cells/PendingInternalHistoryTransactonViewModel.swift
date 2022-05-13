//
//  PendingInternalHistoryTransactonViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 20/04/2022.
//

import UIKit
import BigInt

class PendingInternalHistoryTransactonViewModel: TransactionHistoryItemViewModelProtocol {
  
  let internalTransaction: InternalHistoryTransaction
  
  var fromIconSymbol: String {
    return self.internalTransaction.fromSymbol ?? ""
  }
  
  var toIconSymbol: String {
    return self.internalTransaction.toSymbol ?? ""
  }
  
  var displayedAmountString: String {
    return self.internalTransaction.transactionDescription
  }
  
  var transactionDetailsString: String {
    switch self.internalTransaction.type {
    case .transferNFT, .transferETH, .transferToken:
      if let toAddress = self.internalTransaction.transactionObject?.to {
        return NSLocalizedString("To", value: "To", comment: "") + ": \(toAddress)"
      }
      return ""
    default:
      return self.internalTransaction.transactionDetailDescription
    }
  }
  
  var transactionTypeString: String {
    if self.internalTransaction.state == .speedup {
      return "SPEED UP"
    }

    if self.internalTransaction.state == .cancel {
      return "CANCEL"
    }

    switch self.internalTransaction.type {
    case .swap:
      return "SWAP"
    case .withdraw:
      return "WITHDRAWAL"
    case .transferETH:
      return "TRANSFER"
    case .receiveETH:
      return "RECEIVE"
    case .transferToken:
      return "TRANSFER"
    case .receiveToken:
      return "RECEIVE"
    case .allowance:
      return "APPROVE"
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
    }
  }

  var isError: Bool {
    if self.internalTransaction.state == .pending {
      return false
    } else {
      return self.internalTransaction.state == .error || self.internalTransaction.state == .drop
    }
  }

  var transactionTypeImage: UIImage {
    switch self.internalTransaction.type {
    case .swap:
      return UIImage()
    case .withdraw:
      return UIImage(named: "history_approve_icon")!
    case .transferETH:
      return UIImage(named: "history_send_icon")!
    case .receiveETH:
      return UIImage(named: "history_receive_icon")!
    case .transferToken:
      return UIImage(named: "history_send_icon")!
    case .receiveToken:
      return UIImage(named: "history_receive_icon")!
    case .allowance:
      return UIImage(named: "history_approve_icon")!
    case .earn:
      return UIImage(named: "history_approve_icon")!
    case .contractInteraction:
      return UIImage(named: "history_contract_interaction_icon")!
    case .selfTransfer:
      return UIImage(named: "history_send_icon")!
    case .createNFT:
      return UIImage(named: "history_receive_icon")!
    case .transferNFT:
      return UIImage(named: "history_send_icon")!
    case .receiveNFT:
      return UIImage(named: "history_receive_icon")!
    case .multiSend:
      return UIImage(named: "multiSend_icon")!
    case .claimReward:
      return UIImage(named: "history_claim_reward_icon")!
    }
  }

  var displayTime: String {
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: self.internalTransaction.time)
  }

  init(transaction: InternalHistoryTransaction) {
    self.internalTransaction = transaction
  }
}
