//
//  GameListCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class GameListCell: UICollectionViewCell {
  @IBOutlet weak var collectionView: UICollectionView!
  var onSelectGame: ((Game) -> ())?
  
  var games: [Game] = [] {
    didSet {
      self.collectionView.reloadData()
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    setupCollectionView()
  }
  
  func setupCollectionView() {
    collectionView.registerCellNib(GameItemCell.self)
    
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  func configure(games: [Game]) {
    self.games = games
  }
  
}

extension GameListCell: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return games.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(GameItemCell.self, indexPath: indexPath)!
    cell.configure(game: games[indexPath.item])
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    onSelectGame?(games[indexPath.item])
  }
    
}

extension GameListCell: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return .init(width: 84, height: 156)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return .init(top: 0, left: 32, bottom: 0, right: 32)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 32
  }
  
}
