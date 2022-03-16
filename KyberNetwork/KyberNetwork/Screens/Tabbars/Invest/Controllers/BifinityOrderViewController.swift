//
//  BifinityOrderViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/03/2022.
//

import UIKit

class BifinityOrderViewController: KNBaseViewController {
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  @IBOutlet weak var walletSelectButton: UIButton!
  var orders: [BifinityOrder] = []
  init() {
    super.init(nibName: BifinityOrderViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  func setupUI() {
    self.walletSelectButton.rounded(radius: self.walletSelectButton.frame.size.height / 2)
//    self.walletSelectButton.setTitle(self.viewModel.currentWallet.address, for: .normal)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.selectedSegmentIndex = 1
    segmentedControl.highlightSelectedSegment()
    let nib = UINib(nibName: FiatCryptoHistoryCell.className, bundle: nil)
    self.collectionView.register(nib, forCellWithReuseIdentifier: FiatCryptoHistoryCell.cellID)
  }

  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
  }

  @IBAction func walletSelectButtonTapped(_ sender: UIButton) {

  }

  func coordinatorDidGetOrders(orders: [BifinityOrder]) {
    self.orders = orders
    self.collectionView.reloadData()
  }
}

extension BifinityOrderViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FiatCryptoHistoryCell.cellID, for: indexPath) as! FiatCryptoHistoryCell
    let order = self.orders[indexPath.row]
    cell.updateCell(order: order)
    return cell
  }


  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.orders.count
  }

}

extension BifinityOrderViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      return CGSize(
        width: collectionView.frame.width,
        height: FiatCryptoHistoryCell.height
      )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 24
    )
  }
}
