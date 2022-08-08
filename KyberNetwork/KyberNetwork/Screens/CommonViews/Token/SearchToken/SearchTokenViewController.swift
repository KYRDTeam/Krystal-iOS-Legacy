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
  let onSelectTokenCompletion: ((SwapToken) -> ())? = nil
  let collectionViewLeftPadding = 21.0
  let collectionViewCellPadding = 12.0
  let collectionViewCellWidth = 86.0
  var defaultCommonTokensInOneRow: CGFloat {
    get {
      return UIScreen.main.bounds.size.width - collectionViewLeftPadding * 2 >= collectionViewCellWidth * 4 + collectionViewCellPadding * 3 ? 4 : 3
    }
  }
  var viewModel: SearchTokenViewModel
  var timer: Timer?
  init(viewModel: SearchTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SearchTokenViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.viewModel.getCommonBaseToken {
      self.collectionView.reloadData()
    }
    
    self.viewModel.fetchDataFromAPI(querry: "", orderBy: "usdValue") {
      self.tableView.reloadData()
    }
  }
  
  func setupUI() {
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

extension SearchTokenViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(doSearch), userInfo: nil, repeats: false)
    return true
  }
  
  @objc func doSearch() {
    if let text = self.searchField.text {
      self.viewModel.fetchDataFromAPI(querry: text, orderBy: "usdValue") {
        self.tableView.reloadData()
      }
    }
  }
}

extension SearchTokenViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfSearchTokens()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SearchTokenViewCell.self, indexPath: indexPath)!
    let swapToken = self.viewModel.searchTokens[indexPath.row]
    cell.updateUI(token: swapToken)
    return cell
  }
}

extension SearchTokenViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let onSelectTokenCompletion = self.onSelectTokenCompletion {
      let swapToken = self.viewModel.searchTokens[indexPath.row]
      onSelectTokenCompletion(swapToken)
      self.dismiss(animated: true)
    }
  }
}

extension SearchTokenViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberOfCommonBaseTokens()
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(CommonBaseTokenCell.self, indexPath: indexPath)!
    let token = self.viewModel.commonBaseTokens[indexPath.row]
    cell.updateUI(token: token)
    return cell
  }
}

extension SearchTokenViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let onSelectTokenCompletion = self.onSelectTokenCompletion {
      let token = self.viewModel.commonBaseTokens[indexPath.row]
      let swapToken = SwapToken(token: token)
      onSelectTokenCompletion(swapToken)
      self.dismiss(animated: true)
    }
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
