//
//  KNTransactionFilterViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/04/2022.
//

import Foundation

enum FilterCondition {
  case byTypes(types: [FilteringTransactionType])
  case byTokens(tokens: [String])
  case byDate(from: Date?, to: Date?)
}

enum FilteringTransactionType: String, CaseIterable {
  case transfer = "Transfer"
  case receive = "Received"
  case swap = "Swap"
  case approval = "Approval"
  case withdraw = "Withdraw"
  case supply = "Supply"
  case contractInteraction = "ContractInteration"
  case claimReward = "ClaimReward"
}

class KNTransactionFilterViewModel {
  let defaultDisplayingTokens = 16
  
  var startDate: Date?
  var endDate: Date?
  var selectedTypes: Set<FilteringTransactionType> = .init([])
  var selectedTokens: Set<String> = .init([])
  
  var canLoadMore: Bool = true
  var isSelectingAllTokens: Bool = false
  var displayTokens: [String] = []
  
  var allTypes: [FilteringTransactionType] = FilteringTransactionType.allCases
  var allTokens: [String]
  
  init(allTokens: [String], conditions: [FilterCondition]) {
    self.allTokens = allTokens
    conditions.forEach { condition in
      switch condition {
      case .byTypes(let types):
        self.selectedTypes = Set(types)
      case .byTokens(let tokens):
        self.selectedTokens = Set(tokens)
        self.isSelectingAllTokens = Set(tokens) == Set(allTokens)
      case .byDate(let from, let to):
        self.startDate = from
        self.endDate = to
      }
    }
    displayTokens = Array(allTokens.prefix(defaultDisplayingTokens))
    canLoadMore = allTokens.count > defaultDisplayingTokens
  }
  
  func reset() {
    selectedTypes = []
    selectedTokens = []
    startDate = nil
    endDate = nil
  }
  
  func title(forTransactionType type: FilteringTransactionType) -> String {
    switch type {
    case .transfer:
      return "Transfer" //Strings.send
    case .receive:
      return "Receive"// Strings.receive
    case .swap:
      return "Swap" //Strings.swap
    case .approval:
      return "Approval" //Strings.approval
    case .supply:
      return "Supply" //Strings.supply
    case .contractInteraction:
      return "Contract Interaction" //Strings.contractInteraction
    case .claimReward:
      return "Claim Reward" //Strings.claimReward
    case .withdraw:
      return "Withdraw"
    }
  }
  
  func onSelectTypeAt(index: Int) {
    let type = allTypes[index]
    if selectedTypes.contains(type) {
      selectedTypes.remove(type)
    } else {
      selectedTypes.insert(type)
    }
  }
  
  func onSelectTokenAt(index: Int) {
    let token = displayTokens[index]
    if selectedTokens.contains(token) {
      selectedTokens.remove(token)
    } else {
      selectedTokens.insert(token)
    }
  }
  
}
