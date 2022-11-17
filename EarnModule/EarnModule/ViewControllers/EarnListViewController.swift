//
//  EarnListViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit
import SkeletonView
import BaseModule
import Dependencies
import AppState
import Services
import DesignSystem


protocol EarnListViewControllerDelegate: class {
  func didSelectPlatform(platform: EarnPlatform, pool: EarnPoolModel)
}

class EarnListViewController: InAppBrowsingViewController {
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchFieldActionButton: UIButton!
  @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var emptyView: UIView!
  weak var delegate: EarnListViewControllerDelegate?
  
  @IBOutlet weak var emptyIcon: UIImageView!
  @IBOutlet weak var emptyLabel: UILabel!
  var dataSource: [EarnPoolViewCellViewModel] = []
  var displayDataSource: [EarnPoolViewCellViewModel] = []
  var timer: Timer?
  var currentSelectedChain: ChainType = AppState.shared.isSelectedAllChain ? .all : AppState.shared.currentChain
  override func viewDidLoad() {
    super.viewDidLoad()
    fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
    setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func onAppSwitchChain() {
    currentSelectedChain = AppState.shared.currentChain
    fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
  }
  
  override func onAppSelectAllChain() {
    currentSelectedChain = .all
    fetchData()
  }

  func setupUI() {
    self.searchTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
    self.tableView.registerCellNib(EarnPoolViewCell.self)
  }
  
  func reloadUI() {
    self.emptyView.isHidden = !self.displayDataSource.isEmpty
    self.tableView.reloadData()
  }
  
  func fetchData(chainId: Int? = nil) {
    self.displayDataSource.forEach { viewModel in
      viewModel.isExpanse = false
    }
    reloadUI()
    let service = EarnServices()
    showLoading()
    var chainIdString: String?
    if let chainId = chainId {
      chainIdString = "\(chainId)"
    }
    service.getEarnListData(chainId: chainIdString) { listData in
      var data: [EarnPoolViewCellViewModel] = []
      listData.forEach { earnPoolModel in
        data.append(EarnPoolViewCellViewModel(earnPool: earnPoolModel))
      }
      if data.isEmpty {
        self.emptyIcon.image = UIImage(named: "empty_earn_icon")
        self.emptyLabel.text = Strings.earnIsCurrentlyNotSupportedOnThisChainYet
      }

      self.dataSource = data
      self.displayDataSource = data
      self.hideLoading()
      self.reloadUI()
    }
  }
  
  func updateUIStartSearchingMode() {
    self.view.layoutIfNeeded()
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      self.searchViewRightConstraint.constant = 77
      self.cancelButton.isHidden = false
      self.searchFieldActionButton.setImage(UIImage(named: "close-search-icon"), for: .normal)
      self.view.layoutIfNeeded()
    }
  }
  
  func updateUIEndSearchingMode() {
    self.view.layoutIfNeeded()
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      self.searchViewRightConstraint.constant = 18
      self.cancelButton.isHidden = true
      self.searchFieldActionButton.setImage(UIImage(named: "search_blue_icon"), for: .normal)
      self.view.endEditing(true)
      self.view.layoutIfNeeded()
    }
  }
  
  @IBAction func onSearchButtonTapped(_ sender: Any) {
    if !self.cancelButton.isHidden {
      searchTextField.text = ""
      self.fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
    } else {
      self.updateUIStartSearchingMode()
    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.updateUIEndSearchingMode()
  }

}

extension EarnListViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return displayDataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(EarnPoolViewCell.self, indexPath: indexPath)!
    let viewModel = displayDataSource[indexPath.row]
    cell.updateUI(viewModel: viewModel, shouldShowChainIcon: currentSelectedChain == .all)
    cell.delegate = self
    return cell
  }
}

extension EarnListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var cellViewModel = displayDataSource[indexPath.row]
    cellViewModel.isExpanse = !cellViewModel.isExpanse
    self.tableView.beginUpdates()
    if let cell = self.tableView.cellForRow(at: indexPath) as? EarnPoolViewCell {
      animateCellHeight(cell: cell, viewModel: cellViewModel)
    }
    self.tableView.endUpdates()
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let cellViewModel = displayDataSource[indexPath.row]
    return cellViewModel.height()
  }
  
  func animateCellHeight(cell: EarnPoolViewCell, viewModel: EarnPoolViewCellViewModel) {
    self.view.layoutIfNeeded()
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      var rect = cell.frame
      rect.size.height = viewModel.height()
      cell.frame = rect
      cell.updateUIExpanse(viewModel: viewModel)
      self.view.layoutIfNeeded()
    }
  }
}

extension EarnListViewController: SkeletonTableViewDelegate, SkeletonTableViewDataSource {

  func showLoading() {
    let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
    view.showAnimatedGradientSkeleton(usingGradient: gradient)
  }

  func hideLoading() {
    view.hideSkeleton()
  }

  func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 5
  }

  func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
    let cell = skeletonView.dequeueReusableCell(EarnPoolViewCell.self, indexPath: indexPath)!
    return cell
  }

  func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
    return EarnPoolViewCell.className
  }
}

extension EarnListViewController: UITextFieldDelegate {
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
    if let text = self.searchTextField.text, !text.isEmpty {
      self.displayDataSource = self.dataSource.filter({ viewModel in
        let containSymbol = viewModel.earnPoolModel.token.symbol.lowercased().contains(text.lowercased())
        let containName = viewModel.earnPoolModel.token.name.lowercased().contains(text.lowercased())
        return containSymbol || containName
      })
      if self.displayDataSource.isEmpty {
        self.emptyIcon.image = UIImage(named: "empty-search-token")
        self.emptyLabel.text = Strings.noRecordFound
      }
      self.reloadUI()
    } else {
      self.fetchData(chainId: currentSelectedChain == .all ? nil : currentSelectedChain.getChainId())
    }
  }
}

extension EarnListViewController: EarnPoolViewCellDelegate {
  func didSelectPlatform(platform: EarnPlatform, pool: EarnPoolModel) {
    delegate?.didSelectPlatform(platform: platform, pool: pool)
  }
}
