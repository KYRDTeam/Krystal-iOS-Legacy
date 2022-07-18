//
//  TransactionHistoryItemType.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/05/2022.
//

import Foundation

enum TransactionHistoryItemType: String {
  case swap = "Swap"
  case transfer = "Transfer"
  case receive = "Received"
  case approval = "Approval"
  case supply = "Supply"
  case withdraw = "Withdraw"
  case claimReward = "ClaimReward"
  case bridge = "Bridge"
  case contractInteraction = "ContractInteration"
  case multiSend = "Multi-send"
  case multiReceive = "Multi-receive"
}
