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
  case bridge = "BridgeFrom"
  case contractInteraction = "ContractInteration"
}
