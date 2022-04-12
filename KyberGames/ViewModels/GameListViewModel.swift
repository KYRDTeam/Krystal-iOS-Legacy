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

class GameListViewModel {
  var games: Dynamic<[Game]> = .init(Game.mock)
  var campaigns: Dynamic<[Campaign]> = .init(Campaign.mock)
  var sections: [GameListSection] = [.checkin, .games, .campaigns]
  
  var onTapBack: (() -> ())?
  var onNotificationTap: ((Bool) -> ())?
  var onCheckinTap: (() -> ())?
  var onSelectGame: ((Game) -> ())?
}
