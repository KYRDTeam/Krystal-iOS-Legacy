//
//  BifinityOrderViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/03/2022.
//

import UIKit

protocol BifinityOrderDelegate: class {
  func openWalletList()
}

class BifinityOrderViewModel {
  var orders: [BifinityOrder] = []
  var pendingOrders: [BifinityOrder] {
    var filteredOrder: [BifinityOrder] = []
    self.orders.forEach { order in
      if order.status == "processing" {
        filteredOrder.append(order)
      }
    }
    return filteredOrder
  }
  var completedOrders: [BifinityOrder] {
    var filteredOrder: [BifinityOrder] = []
    self.orders.forEach { order in
      if order.status != "processing" {
        filteredOrder.append(order)
      }
    }
    return filteredOrder
  }
  var isShowingPending: Bool = true
  var wallet: Wallet
  init(wallet: Wallet) {
    self.wallet = wallet
  }

  func numberOfRows() -> Int {
    return self.isShowingPending ? self.pendingOrders.count : self.completedOrders.count
  }

  func orderForRows(indexPath: IndexPath) -> BifinityOrder {
    return self.isShowingPending ? self.pendingOrders[indexPath.row] : self.completedOrders[indexPath.row]
  }
}

class BifinityOrderViewController: KNBaseViewController {
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  @IBOutlet weak var walletSelectButton: UIButton!
  @IBOutlet weak var emptyStateContainerView: UIView!
  @IBOutlet weak var orderNowButton: UIButton!

  let viewModel: BifinityOrderViewModel
  weak var delegate: BifinityOrderDelegate?
  init(viewModel: BifinityOrderViewModel) {
    self.viewModel = viewModel
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
    self.walletSelectButton.setTitle(self.viewModel.wallet.address.description, for: .normal)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.selectedSegmentIndex = 1
    segmentedControl.highlightSelectedSegment()
    let nib = UINib(nibName: FiatCryptoHistoryCell.className, bundle: nil)
    self.collectionView.register(nib, forCellWithReuseIdentifier: FiatCryptoHistoryCell.cellID)
    self.orderNowButton.rounded(color: UIColor(named: "buttonBackgroundColor")!, width: 1, radius: self.orderNowButton.frame.size.height / 2)
    self.updateCollectionView()
  }

  func updateCollectionView() {
    self.emptyStateContainerView.isHidden = self.viewModel.numberOfRows() > 0
    self.collectionView.reloadData()
  }

  @IBAction func orderButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    self.viewModel.isShowingPending = sender.selectedSegmentIndex == 1
    self.updateCollectionView()
  }

  @IBAction func walletSelectButtonTapped(_ sender: UIButton) {
    self.delegate?.openWalletList()
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  func coordinatorDidGetOrders(orders: [BifinityOrder]) {
    guard self.isViewLoaded else { return }
    self.viewModel.orders = orders
    self.updateCollectionView()
  }

  func coordinatorDidUpdateWallet(_ wallet: Wallet) {
    guard self.isViewLoaded else { return }
    self.viewModel.wallet = wallet
    self.walletSelectButton.setTitle(self.viewModel.wallet.address.description, for: .normal)
  }
}

extension BifinityOrderViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FiatCryptoHistoryCell.cellID, for: indexPath) as! FiatCryptoHistoryCell
    let order = self.viewModel.orderForRows(indexPath: indexPath)
    cell.updateCell(order: order, indexPath: indexPath)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberOfRows()
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
      height: 0
    )
  }
}
