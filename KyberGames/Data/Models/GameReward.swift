//
//  GameReward.swift
//  KyberGames
//
//  Created by Nguyen Tung on 12/04/2022.
//

import UIKit

struct GameReward: Decodable {
  var title: String
  var color: String
  
  var uiColor: UIColor { return UIColor(hexString: color) }
  
  static let mock: [GameReward] = {
    let url = Bundle(for: KyberGamesModule.self).url(forResource: "mock_spin_rewards", withExtension: "json")!
    let data = try! Data(contentsOf: url)
    return try! JSONDecoder().decode([GameReward].self, from: data)
  }()
  
}
