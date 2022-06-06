//
//  ExploreViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import UIKit

enum ExploreMenuItem: CaseIterable {
  case swap
  case transfer
  case reward
  case referral
  case dapps
  case multisend
  case buyCrypto
  case promotion
  case rewardHunting
  case bridge
}

enum ExploreSection {
  case banners
  case menu
  case partners
}

class ExploreViewModel {
  
  var banners: Dynamic<[Asset]> = .init([])
  var menuItems: Dynamic<[ExploreMenuItem]> = .init([])
  var partners: Dynamic<[Asset]> = .init([])
  
  var sections: [ExploreSection] = [.banners, .menu, .partners]
  
  func onViewLoaded() {
    observeFeatureFlagChanged()
  }
  
  func observeFeatureFlagChanged() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reloadMenuItems),
      name: Notification.Name(kUpdateFeatureFlag),
      object: nil
    )
  }
  
  @objc func reloadMenuItems() {
    let isBuyCryptoEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.bifinityIntegration)
    let isPromoCodeEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.promotionCodeIntegration)
    let isRewardHuntingEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.rewardHunting)
    let isBridgeEnabled = true //FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.rewardHunting)
    
    var menuItems: [ExploreMenuItem] = []
    menuItems.append(.swap)
    menuItems.append(.transfer)
    
    if KNGeneralProvider.shared.currentChain.isSupportSwap() {
      menuItems.append(contentsOf: [.reward, .referral, .dapps, .multisend])
      
      if isBuyCryptoEnabled {
        menuItems.append(.buyCrypto)
      }
      if isPromoCodeEnabled {
        menuItems.append(.promotion)
      }
    }
    
    if isRewardHuntingEnabled {
      menuItems.append(.rewardHunting)
    }
    if isBridgeEnabled {
      menuItems.append(.bridge)
    }
    if self.menuItems.value != menuItems {
      self.menuItems.value = menuItems
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kUpdateFeatureFlag),
      object: nil
    )
  }
  
}
