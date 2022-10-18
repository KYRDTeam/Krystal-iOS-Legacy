//
//  EarnListViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit
import SkeletonView

class EarnListViewController: InAppBrowsingViewController {
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchFieldActionButton: UIButton!
  @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var emptyView: UIView!
  var dataSource: [EarnPoolViewCellViewModel] = []
  var displayDataSource: [EarnPoolViewCellViewModel] = []
  var timer: Timer?
  override func viewDidLoad() {
    super.viewDidLoad()
    fetchData()
    setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  func setupUI() {
    self.searchTextField.setPlaceholder(text: Strings.searchPools, color: .Kyber.normalText)
    self.tableView.registerCellNib(EarnPoolViewCell.self)
  }
  
  func reloadUI() {
    self.emptyView.isHidden = !self.displayDataSource.isEmpty
    self.tableView.reloadData()
  }
  
  func fetchData(chainId: Int = KNGeneralProvider.shared.currentChain.getChainId()) {
    let service = EarnServices()
    showLoading()
    service.getEarnListData(chainId: nil) { listData in
      var data: [EarnPoolViewCellViewModel] = []
      listData.forEach { earnPoolModel in
        data.append(EarnPoolViewCellViewModel(earnPool: earnPoolModel))
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
      self.fetchData()
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
    cell.updateUI(viewModel: viewModel)
    return cell
  }
}

extension EarnListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var cellViewModel = displayDataSource[indexPath.row]
    cellViewModel.isExpanse = !cellViewModel.isExpanse
    DispatchQueue.main.async {
      self.tableView.beginUpdates()
      if let cell = self.tableView.cellForRow(at: indexPath) as? EarnPoolViewCell {
        self.animateCellHeight(cell: cell, viewModel: cellViewModel)
      }
      self.tableView.endUpdates()
    }
    
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let cellViewModel = displayDataSource[indexPath.row]
    return cellViewModel.height()
  }
  
  func animateCellHeight(cell: EarnPoolViewCell, viewModel: EarnPoolViewCellViewModel) {
    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      var rect = cell.frame
      rect.size.height = viewModel.height()
      cell.frame = rect
      cell.updateUIExpanse(viewModel: viewModel)
      self.view.endEditing(true)
      self.view.layoutIfNeeded()
    }
  }
}

extension EarnListViewController: SkeletonTableViewDelegate, SkeletonTableViewDataSource {

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
      self.reloadUI()
    } else {
      self.fetchData()
    }
  }
}
