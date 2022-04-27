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
}

class RewardHuntingViewModel {
  var actions: RewardHuntingViewModelActions?
  let url: URL
  
  init(url: URL) {
    self.url = url
  }
  
  func didTapBack() {
    actions?.goBack()
  }
  
  func didTapRewards() {
    actions?.openRewards()
  }

}
