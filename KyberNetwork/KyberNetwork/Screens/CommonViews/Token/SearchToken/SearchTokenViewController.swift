//
//  SearchTokenViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 02/08/2022.
//

import UIKit
import SkeletonView

class SearchTokenViewController: KNBaseViewController {

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchField: UITextField!
  @IBOutlet weak var searchFieldActionButton: UIButton!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
  @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
  @IBOutlet weak var topView: UIView!
  @IBOutlet weak var topViewHeight: NSLayoutConstraint!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var emptyView: UIView!

  var onSelectTokenCompletion: ((SwapToken) -> Void)?
  let collectionViewLeftPadding = 21.0
  let collectionViewCellPadding = 12.0
  let collectionViewCellWidth = 86.0
  var defaultCommonTokensInOneRow: CGFloat {
    return UIScreen.main.bounds.size.width - collectionViewLeftPadding * 2 >= collectionViewCellWidth * 4 + collectionViewCellPadding * 3 ? 4 : 3
  }
  var viewModel: SearchTokenViewModel
  var timer: Timer?
  var isSourceToken: Bool = true
  var orderBy: String {
    return self.isSourceToken ? "usdValue" : "tag"
  }
  
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
    self.showLoading()
    self.viewModel.fetchDataFromAPI(query: "", orderBy: self.orderBy) { [weak self] in
      self?.hideLoading()
      self?.reloadUI()
    }
    MixPanelManager.track("search_open", properties: ["screenid": "search"])
  }
  
  func setupUI() {
    self.view.isUserInteractionDisabledWhenSkeletonIsActive = false
    self.searchField.setPlaceholder(text: Strings.findTokenByNameSymbolAddress, color: .Kyber.normalText)
    self.tableView.registerCellNib(SearchTokenViewCell.self)
    self.tableView.registerCellNib(OverviewSkeletonCell.self)
    self.tableView.tableHeaderView = .init(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
    self.tableView.sectionHeaderHeight = 0
    self.collectionView.registerCellNib(CommonBaseTokenCell.self)
    self.collectionViewHeight.constant = 40 * 2 + 16
  }
  
  func reloadUI() {
    self.emptyView.isHidden = !self.viewModel.searchTokens.isEmpty
    self.tableView.reloadData()
  }
  
  func updateUIStartSearchingMode() {
    self.view.layoutIfNeeded()
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      self.searchViewRightConstraint.constant = 77
      self.topViewHeight.constant = 0
      self.topView.isHidden = true
      self.cancelButton.isHidden = false
      self.searchFieldActionButton.setImage(UIImage(named: "close-search-icon"), for: .normal)
      self.view.layoutIfNeeded()
    }
  }
  
  func updateUIEndSearchingMode() {
    self.view.layoutIfNeeded()
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      self.searchViewRightConstraint.constant = 21
      self.topViewHeight.constant = 90
      self.topView.isHidden = false
      self.cancelButton.isHidden = true
      self.searchFieldActionButton.setImage(UIImage(named: "search_blue_icon"), for: .normal)
      self.view.endEditing(true)
      self.view.layoutIfNeeded()
    }
  }

  @IBAction func closeButtonTapped(_ sender: Any) {
    self.dismiss(animated: true)
  }
  
  @IBAction func onSearchButtonTapped(_ sender: Any) {
    if self.topView.isHidden {
      searchField.text = ""
      self.showLoading()
      self.viewModel.fetchDataFromAPI(query: "", orderBy: self.orderBy) { [weak self] in
        self?.hideLoading()
        self?.reloadUI()
      }
    } else {
      self.updateUIStartSearchingMode()
    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.updateUIEndSearchingMode()
  }
  
  func disableSearch() {
    searchField.text = ""
    updateUIEndSearchingMode()
    showLoading()
    self.viewModel.fetchDataFromAPI(query: "", orderBy: self.orderBy) { [weak self] in
      self?.hideLoading()
      self?.reloadUI()
    }
  }
}

extension SearchTokenViewController: UITextFieldDelegate {
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    self.updateUIStartSearchingMode()
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateUIEndSearchingMode()
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(doSearch), userInfo: nil, repeats: false)
    return true
  }
  
  @objc func doSearch() {
    if let text = self.searchField.text {
      self.showLoading()
      self.viewModel.fetchDataFromAPI(query: text, orderBy: self.orderBy) {
        self.hideLoading()
        self.reloadUI()
      }
    }
  }
}

extension SearchTokenViewController {
  
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
    let token = self.viewModel.commonBaseTokens[indexPath.row]
    let symbolWidth = token.symbol.width(withConstrainedHeight: 18, font: UIFont.Kyber.regular(with: 14))
    
    return CGSize(width: symbolWidth + 50, height: 36)
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

extension SearchTokenViewController: SkeletonTableViewDelegate, SkeletonTableViewDataSource {
  
  func showLoading() {
    let gradient = SkeletonGradient(baseColor: UIColor.Kyber.cellBackground)
    view.showAnimatedGradientSkeleton(usingGradient: gradient)
  }
  
  func hideLoading() {
    view.hideSkeleton()
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
    let cell = skeletonView.dequeueReusableCell(OverviewSkeletonCell.self, indexPath: indexPath)!
    return cell
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
    return OverviewSkeletonCell.className
  }
  
}
