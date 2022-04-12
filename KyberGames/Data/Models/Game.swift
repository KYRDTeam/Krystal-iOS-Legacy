//
//  Game.swift
//  KyberGames
//
//  Created by Nguyen Tung on 12/04/2022.
//

import Foundation

struct Game: Decodable {
  var id: String
  var image: String
  var title: String
  
  static let mock: [Game] = {
    let url = Bundle(for: KyberGamesModule.self).url(forResource: "mock_games", withExtension: "json")!
    let data = try! Data(contentsOf: url)
    return try! JSONDecoder().decode([Game].self, from: data)
  }()
}
