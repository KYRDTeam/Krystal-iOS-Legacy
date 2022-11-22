//
//  ExploreMenuItemViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import Foundation
import UIKit

class ExploreMenuItemViewModel {
  
  let item: ExploreMenuItem
  
  init(item: ExploreMenuItem) {
    self.item = item
  }
  
  var title: String {
    switch item {
    case .swap:
      return Strings.swap
    case .transfer:
      return Strings.transfer
    case .reward:
      return Strings.reward
    case .referral:
      return Strings.referral
    case .dapps:
      return Strings.dApps
    case .multisend:
      return Strings.multiSend
    case .buyCrypto:
      return Strings.buyCrypto
    case .promotion:
      return Strings.promotion
    case .rewardHunting:
      return Strings.rewardHunting
    case .bridge:
      return Strings.KrystalBridge
    case .scanner:
      return Strings.scanner
    case .stake:
      return Strings.Staking
    case .approvals:
        return Strings.approvalMenuTitle
    }
  }
  
  var icon: UIImage {
    switch item {
    case .swap:
      return Images.exploreSwapIcon
    case .transfer:
      return Images.exploreTransferIcon
    case .reward:
      return Images.exploreRewardIcon
    case .referral:
      return Images.exploreReferralIcon
    case .dapps:
      return Images.exploreDappsIcon
    case .multisend:
      return Images.exploreMultisendIcon
    case .buyCrypto:
      return Images.exploreBuyCryptoIcon
    case .promotion:
      return Images.explorePromotionIcon
    case .rewardHunting:
      return Images.exploreRewardHuntingIcon
    case .bridge:
      return Images.exploreBridgeIcon
    case .scanner:
      return Images.exploreScannerIcon
    case .stake:
      return Images.exploreStakeIcon
    case .approvals:
        return Images.exploreApprovalIcon
    }
  }
    
    var isNewFeature: Bool {
        switch item {
        case .approvals, .stake:
            return true
        default:
            return false
        }
    }
  
}
