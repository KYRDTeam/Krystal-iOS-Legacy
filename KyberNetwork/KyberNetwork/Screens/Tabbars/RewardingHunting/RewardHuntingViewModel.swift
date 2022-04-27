//
//  RewardHuntingViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 27/04/2022.
//

import Foundation

struct RewardHuntingViewModelActions {
  var goBack: () -> ()
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

}
