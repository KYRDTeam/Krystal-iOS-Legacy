//
//  GameListViewController.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

class GameListViewController: BaseViewController {
  
  @IBOutlet weak var collectionView: UICollectionView!
  
  var viewModel: GameListViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupNavigationBar()
    setupCollectionView()
    bindViewModel()
  }
  
  func setupNavigationBar() {
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  func setupCollectionView() {
    collectionView.registerCellNib(CheckinBoardCell.self)
    collectionView.registerCellNib(GameListCell.self)
    collectionView.registerCellNib(CampaignListCell.self)
    
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  func bindViewModel() {
    
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    viewModel.onTapBack?()
  }
  
}

extension GameListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return viewModel.sections.count
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionType = viewModel.sections[section]
    
    switch sectionType {
    case .checkin:
      return 1
    case .games:
      return 1
    case .campaigns:
      return 1
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let sectionType = viewModel.sections[indexPath.section]
    
    switch sectionType {
    case .checkin:
      let cell = collectionView.dequeueReusableCell(CheckinBoardCell.self, indexPath: indexPath)!
      cell.notificationTap = viewModel.onNotificationTap
      cell.checkinTap = viewModel.onCheckinTap
      return cell
    case .games:
      let cell = collectionView.dequeueReusableCell(GameListCell.self, indexPath: indexPath)!
      cell.configure(games: viewModel.games.value)
      cell.onSelectGame = { [weak self] game in
        self?.viewModel.onSelectGame?(game)
      }
      return cell
    case .campaigns:
      let cell = collectionView.dequeueReusableCell(CampaignListCell.self, indexPath: indexPath)!
      cell.configure(campaigns: viewModel.campaigns.value)
      return cell
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
  }
  
}

extension GameListViewController: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    let sectionType = viewModel.sections[section]
    
    switch sectionType {
    case .checkin:
      return .zero
    case .games:
      return .init(top: 24, left: 0, bottom: 0, right: 0)
    case .campaigns:
      return .init(top: 24, left: 0, bottom: 32, right: 0)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let sectionType = viewModel.sections[indexPath.section]
    
    switch sectionType {
    case .checkin:
      return .init(width: collectionView.frame.width, height: 260)
    case .games:
      return .init(width: collectionView.frame.width, height: 156)
    case .campaigns:
      return .init(width: collectionView.frame.width, height: 150)
    }
  }
  
}
