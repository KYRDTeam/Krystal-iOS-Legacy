//
//  GameTaskCellViewModel.swift
//  KyberGames
//
//  Created by Nguyen Tung on 12/04/2022.
//

import UIKit

class GameTaskCellViewModel {
  
  let task: GameTask
  
  init(task: GameTask) {
    self.task = task
  }
  
  var image: UIImage? {
    return icon(forTask: task)
  }
  
  var title: String {
    return task.title
  }
  
  var description: String {
    return task.description
  }
  
  var action: String? {
    return action(forTask: task)
  }
  
  var rewardString: String {
    return "+\(task.turns) turn"
  }
  
  private func action(forTask task: GameTask) -> String? {
    switch task.taskType {
    case .checkin:
      return "Check In"
    case .refer:
      return "Refer Friend"
    case .multisend:
      return "Send Now"
    default:
      return nil
    }
  }
  
  private func icon(forTask task: GameTask) -> UIImage? {
    switch task.taskType {
    case .checkin:
      return Images.challengeCheckin
    case .refer:
      return Images.challengeRefer
    case .multisend:
      return Images.challengeSend
    default:
      return nil
    }
  }
  
}
