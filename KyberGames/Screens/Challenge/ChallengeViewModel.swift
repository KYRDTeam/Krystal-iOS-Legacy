//
//  ChallengeViewModel.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import Foundation

struct ChallengeStep {
  var title: String
  var completedActions: Int
  var totalActions: Int
  
  var isCompleted: Bool {
    return completedActions == totalActions
  }
}

struct ChallengeReward {
  var icon: String
  var title: String
  var description: String
}

enum ChallengeItemModel {
  case info
  case begin
  case progress(step: ChallengeStep)
  case rewardTitle
  case reward(reward: ChallengeReward)
}

class ChallengeViewModel {
  var items: [ChallengeItemModel] = [
    .info,
    .begin,
    .progress(
      step: .init(
        title: "Make 50 swap transactions (min $10)",
        completedActions: 28,
        totalActions: 50
      )
    ),
    .progress(
      step: .init(
        title: "Make 10 transfer transactions (with long text in 2nd line)",
        completedActions: 10,
        totalActions: 10
      )
    ),
    .rewardTitle,
    .reward(
      reward: .init(
        icon: "",
        title: "10 BUSD",
        description: "420 BUSD left"
      )
    ),
    .reward(
      reward: .init(
        icon: "",
        title: "1200 Krystal points",
        description: "2,000 Krystal point left"
      )
    )
  ]
  
  var onTapBack: (() -> ())?
}
