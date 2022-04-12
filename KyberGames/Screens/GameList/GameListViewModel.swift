//
//  GameListViewModel.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import Foundation

enum GameListSection {
  case checkin
  case games
  case campaigns
}

struct Campaign: Decodable {
  var image: String
  var title: String
  
  static let mock: [Campaign] = [
    .init(image: "", title: ""),
    .init(image: "", title: ""),
    .init(image: "", title: ""),
  ]
}

struct Game {
  var id: Int
  var icon: String
  var name: String
  
  static let mock: [Game] = [
    .init(id: 0, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin"),
    .init(id: 1, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin"),
    .init(id: 2, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin"),
    .init(id: 3, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin"),
    .init(id: 4, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin"),
    .init(id: 5, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin"),
    .init(id: 6, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin"),
    .init(id: 7, icon: "https://play-lh.googleusercontent.com/4rd9hPlKvE1QNHwcxOYdCidRzUb8PtkeD_AG_bhgJZLv9kZkvdhZHV26SgJk3vWBhwI", name: "Lucky Spin")
  ]
}

class GameListViewModel {
  var games: Dynamic<[Game]> = .init(Game.mock)
  var campaigns: Dynamic<[Campaign]> = .init(Campaign.mock)
  var sections: [GameListSection] = [.checkin, .games, .campaigns]
  
  var onTapBack: (() -> ())?
  var onNotificationTap: ((Bool) -> ())?
  var onCheckinTap: (() -> ())?
}
