//
//  RewardHuntingViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import Foundation

struct RewardHuntingViewModelActions {
  var goBack: () -> ()
  var openRewards: () -> ()
  var onUpdateSession: (KNSession) -> ()
  var onClose: () -> ()
}

class RewardHuntingViewModel {
  var actions: RewardHuntingViewModelActions?
  var session: KNSession
  var onUpdateSession: (() -> ())?
  
  init(session: KNSession) {
    self.session = session
  }
  
  var url: URL {
    return URL(string: KNEnvironment.default.krystalWebUrl + "/" + Constants.rewardHuntingPath)!
      .appending("address", value: session.wallet.address.description)
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
      selector: #selector(appDidUpdateSession),
      name: Notification.Name(kAppDidUpdateNewSession),
      object: nil
    )
  }
  
  @objc func appDidUpdateSession(notification: Notification) {
    guard let session = notification.userInfo?["session"] as? KNSession else {
       return
    }
    self.session = session
    
    let isRewardHuntingEnabled = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.rewardHunting)
    let isImportedWallet = isImportedWallet(address: session.wallet.address.description)
    
    if isRewardHuntingEnabled && isImportedWallet {
      self.onUpdateSession?()
      self.actions?.onUpdateSession(session)
    } else {
      self.actions?.onClose()
    }
  }
  
  private func isImportedWallet(address: String) -> Bool {
    return KNWalletStorage.shared.realWallets.contains { wallet in
      wallet.address.description == address
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
