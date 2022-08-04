//
//  SearchTokenViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 02/08/2022.
//

import UIKit

class SearchTokenViewController: KNBaseViewController {

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchField: UITextField!
  @IBOutlet weak var searchFieldActionButton: UIButton!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
  
  let collectionViewLeftPadding = 21.0
  let collectionViewCellPadding = 12.0
  let collectionViewCellWidth = 86.0

  var defaultCommonTokensInOneRow: CGFloat {
    get {
      return UIScreen.main.bounds.size.width - collectionViewLeftPadding * 2 >= collectionViewCellWidth * 4 + collectionViewCellPadding * 3 ? 4 : 3
    }
  }

  init(viewModel: KNSearchTokenViewModel) {
    super.init(nibName: SearchTokenViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.searchField.setPlaceholder(text: Strings.searchByTokenWalletEND, color: UIColor(named: "normalTextColor")!)
    self.tableView.registerCellNib(SearchTokenViewCell.self)
    self.collectionView.registerCellNib(CommonBaseTokenCell.self)
    self.collectionViewHeight.constant = 40 * 2 + 16
  }

  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.dismiss(animated: true)
  }
  
  @IBAction func onSearchButtonTapped(_ sender: Any) {
  }
}

extension SearchTokenViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 15
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SearchTokenViewCell.self, indexPath: indexPath)!
    return cell
  }
}

extension SearchTokenViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 4//section == 0 ? 3 : 1
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(CommonBaseTokenCell.self, indexPath: indexPath)!
    cell.tokenLabel.text = "s+ \(indexPath.row)"
    return cell
  }
}

extension SearchTokenViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: 86, height: 36)
  }
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return collectionViewCellPadding
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    let rightPadding = UIScreen.main.bounds.size.width - (collectionViewLeftPadding + defaultCommonTokensInOneRow * collectionViewCellWidth + (defaultCommonTokensInOneRow - 1) * collectionViewCellPadding)
    return UIEdgeInsets(top: 8, left: collectionViewLeftPadding, bottom: 8, right: rightPadding)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
      return collectionViewCellPadding
  }
}
