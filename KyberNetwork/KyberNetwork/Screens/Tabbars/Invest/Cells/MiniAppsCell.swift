//
//  MiniAppsCell.swift
//  KyberNetwork
//
//  Created by Com1 on 23/05/2022.
//

import UIKit

class MiniAppsCell: UITableViewCell {
  @IBOutlet weak var collectionView: UICollectionView!
  var isSpecialApp: Bool = false
  override func awakeFromNib() {
    self.collectionView.registerCellNib(MiniAppCollectionCell.self)
    self.collectionView.registerCellNib(MiniAppBigFeatureCell.self)
    self.collectionView.dataSource = self
    self.collectionView.delegate = self
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
    
}
  
extension MiniAppsCell: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 10
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if self.isSpecialApp {
      let cell = collectionView.dequeueReusableCell(MiniAppBigFeatureCell.self, indexPath: indexPath)!
//      cell.titleLabel.text = "Krystal"
//      cell.imageView.image = UIImage(named: "krystalgo")
      return cell
    } else {
      let cell = collectionView.dequeueReusableCell(MiniAppCollectionCell.self, indexPath: indexPath)!
      cell.titleLabel.text = "Krystal"
      cell.imageView.image = UIImage(named: "krystalgo")
      return cell
    }
    
  }
}

extension MiniAppsCell: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if self.isSpecialApp {
      return CGSize(width: 340, height: 220)
    } else {
      return CGSize(width: 156, height: 156)
    }
  }
}
