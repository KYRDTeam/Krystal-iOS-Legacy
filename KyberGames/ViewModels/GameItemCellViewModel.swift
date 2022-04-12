//
//  GameItemCellViewModel.swift
//  KyberGames
//
//  Created by Nguyen Tung on 12/04/2022.
//

import Foundation

class GameItemCellViewModel {
  
  let game: Game
  
  init(game: Game) {
    self.game = game
  }
  
  var image: String {
    return game.image
  }
  
  var title: String {
    return game.title
  }
  
}
