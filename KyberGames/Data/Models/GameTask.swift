//
//  GameTask.swift
//  KyberGames
//
//  Created by Nguyen Tung on 12/04/2022.
//

import Foundation

enum GameTaskType: String {
  case checkin
  case refer
  case multisend
}

struct GameTask: Decodable {
  var title: String
  var description: String
  var type: String
  var turns: Int
  
  var taskType: GameTaskType? {
    return .init(rawValue: type)
  }
  
  static let mock: [GameTask] = {
    let url = Bundle(for: KyberGamesModule.self).url(forResource: "mock_game_tasks", withExtension: "json")!
    let data = try! Data(contentsOf: url)
    return try! JSONDecoder().decode([GameTask].self, from: data)
  }()
}
