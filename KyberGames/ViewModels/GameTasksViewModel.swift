//
//  GameTasksViewModel.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import Foundation
import UIKit

class GameTasksViewModel {
  var tasks: [GameTask] = GameTask.mock
  var onTapBack: (() -> ())?
}
