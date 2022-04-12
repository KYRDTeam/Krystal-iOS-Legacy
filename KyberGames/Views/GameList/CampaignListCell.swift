//
//  CampaignListCell.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit

class CampaignListCell: UICollectionViewCell {
  @IBOutlet weak var collectionView: UICollectionView!
  
  var campaigns: [Campaign] = [] {
    didSet {
      self.collectionView.reloadData()
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    setupCollectionView()
  }
  
  func setupCollectionView() {
    collectionView.registerCellNib(CampaignItemCell.self)
    
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  func configure(campaigns: [Campaign]) {
    self.campaigns = campaigns
  }
  
}

extension CampaignListCell: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return campaigns.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(CampaignItemCell.self, indexPath: indexPath)!
    return cell
  }
  
}

extension CampaignListCell: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return .init(width: 300, height: 150)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return .init(top: 0, left: 20, bottom: 0, right: 20)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 12
  }
  
}
