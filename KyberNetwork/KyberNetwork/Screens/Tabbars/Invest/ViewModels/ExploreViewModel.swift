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
    case scanner
    case approvals
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
        let isPromoCodeEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.promotionCodeIntegration)
        let isRewardHuntingEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.rewardHunting)
        let isScannerEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.scanner)
        let isTokenApprovalEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.tokenApproval)
        let isNotBrowsing = !KNGeneralProvider.shared.isBrowsingMode
        
        var menuItems: [ExploreMenuItem] = []
        menuItems.append(.swap)
        menuItems.append(.transfer)
        menuItems.append(.buyCrypto)
        menuItems.append(.bridge)
        
        if KNGeneralProvider.shared.currentChain.isSupportSwap() {
            menuItems.append(contentsOf: [.dapps, .multisend])
            
            if isNotBrowsing {
                menuItems.append(contentsOf: [.reward, .referral])
            }
            
            if isPromoCodeEnabled && isNotBrowsing {
                menuItems.append(.promotion)
            }
        }
        if isRewardHuntingEnabled && isNotBrowsing {
            menuItems.append(.rewardHunting)
        }
        
        if isScannerEnabled && isNotBrowsing {
            menuItems.append(.scanner)
        }
        
        if isTokenApprovalEnabled && isNotBrowsing {
            menuItems.append(.approvals)
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
