//
//  ChallengeTasksViewModel.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import Foundation
import UIKit

enum ChallengeTaskType {
  case checkin
  case refer
  case multisend
  
  var action: String {
    switch self {
    case .checkin:
      return "Check In"
    case .refer:
      return "Refer Friend"
    case .multisend:
      return "Send Now"
    }
  }
  
  var icon: UIImage {
    switch self {
    case .checkin:
      return Images.challengeCheckin
    case .refer:
      return Images.challengeRefer
    case .multisend:
      return Images.challengeSend
    }
  }
}

struct ChallengeTask {
  var title: String
  var description: String
  var type: ChallengeTaskType
  var turns: Int
}

class ChallengeTasksViewModel {
  var tasks: [ChallengeTask] = [
    .init(
      title: "Daily Check-In",
      description: "Etiam eu enim pretium, lacinia metus vel, auctor lectus.",
      type: .checkin,
      turns: 1
    ),
    .init(
      title: "Refer a friend",
      description: "Etiam eu enim pretium, lacinia metus vel, auctor lectus.",
      type: .refer,
      turns: 2
    ),
    .init(
      title: "Use Multi-Send",
      description: "Etiam eu enim pretium",
      type: .multisend,
      turns: 1
    )
  ]
  
  var onTapBack: (() -> ())?
}
