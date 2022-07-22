//
//  RewardHuntingViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import Foundation
import KrystalWallets

struct RewardHuntingViewModelActions {
  var goBack: () -> ()
  var openRewards: () -> ()
  var onClose: () -> ()
}

class RewardHuntingViewModel {
  var actions: RewardHuntingViewModelActions?
  var onSwitchAddress: (() -> ())?
  
  var address: KAddress {
    return AppDelegate.session.address
  }

  var url: URL {
    return URL(string: KNEnvironment.default.krystalWebUrl + "/" + Constants.rewardHuntingPath)!
      .appending("address", value: address.addressString)
  }
  
  func didTapBack() {
    actions?.goBack()
  }
  
  func didTapRewards() {
    actions?.openRewards()
  }
  
  func onViewLoaded() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(appDidSwitchAddress),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  @objc func appDidSwitchAddress() {
    let isRewardHuntingEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.rewardHunting)
    
    if isRewardHuntingEnabled && !address.isWatchWallet {
      self.onSwitchAddress?()
    } else {
      self.actions?.onClose()
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kAppDidUpdateNewSession),
      object: nil
    )
  }

}
