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
  var dataSource: [MiniApp] = []
  var selectCompletion: ((MiniApp) -> Void)?
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
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.dataSource.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let miniApp = self.dataSource[indexPath.row]
    if self.isSpecialApp {
      let cell = collectionView.dequeueReusableCell(MiniAppBigFeatureCell.self, indexPath: indexPath)!
      if let url = URL(string: miniApp.icon) {
        cell.icon.setImage(with: url, placeholder: nil)
      }
      cell.ratingLabel.text = String(format: "%.1f", miniApp.rating)
      cell.reviewsLabel.text = "\(miniApp.numberOfReviews) reviews"
      cell.nameLabel.text = miniApp.name
      return cell
    } else {
      let cell = collectionView.dequeueReusableCell(MiniAppCollectionCell.self, indexPath: indexPath)!
      cell.titleLabel.text = miniApp.name
      if let url = URL(string: miniApp.icon) {
        cell.imageView?.setImage(with: url, placeholder: nil)
      }
      cell.rateLabel.text = String(format: "%.1f", miniApp.rating)
      cell.reviewsLabel.text = "\(miniApp.numberOfReviews) reviews"
      return cell
    }
    
  }
}

extension MiniAppsCell: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let miniApp = self.dataSource[indexPath.row]
    if let selectCompletion = self.selectCompletion {
      selectCompletion(miniApp)
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
