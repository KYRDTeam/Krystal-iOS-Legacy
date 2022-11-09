//
//  StakingEarningTokensView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 28/10/2022.
//

import Foundation
import UIKit
import Services
import Utilities

protocol StakingEarningTokensViewDelegate: class {
  func didSelectEarningToken(_ token: EarningToken)
}

class StakingEarningTokensViewModel {
  var dataSource: [EarningToken] = []
  var seletedIndex = 0
}

@IBDesignable
class StakingEarningTokensView: BaseXibView {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tokensCollectionView: UICollectionView!
  
  let viewModel = StakingEarningTokensViewModel()
  weak var delegate: StakingEarningTokensViewDelegate?
  
  override func commonInit() {
    super.commonInit()
    
    registerCell()
  }
  
  private func registerCell() {
    tokensCollectionView.registerCellNib(EarningTokenCell.self)
  }
  
  func updateData(_ data: [EarningToken]) {
    viewModel.dataSource = data
    tokensCollectionView.reloadData()
  }
}

extension StakingEarningTokensView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewModel.dataSource.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(EarningTokenCell.self, indexPath: indexPath)!
    let data = viewModel.dataSource[indexPath.row]
    cell.updateCell(data, selected: viewModel.seletedIndex == indexPath.row)
    return cell
  }
  
}

extension StakingEarningTokensView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    viewModel.seletedIndex = indexPath.row
    tokensCollectionView.reloadData()
    delegate?.didSelectEarningToken(viewModel.dataSource[indexPath.row])
  }
}
