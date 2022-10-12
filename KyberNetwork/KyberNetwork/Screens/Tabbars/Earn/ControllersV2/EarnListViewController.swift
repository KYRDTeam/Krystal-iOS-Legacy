//
//  EarnListViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit

class EarnListViewController: InAppBrowsingViewController {
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchFieldActionButton: UIButton!
  @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cancelButton: UIButton!
  
  var dataSource: [EarnPoolViewCellViewModel] = []
  var timer: Timer?
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  func setupUI() {
    self.searchTextField.setPlaceholder(text: Strings.searchPools, color: .Kyber.normalText)
    self.tableView.registerCellNib(EarnPoolViewCell.self)
    
    for index in 1 ..< 5 {
      dataSource.append(EarnPoolViewCellViewModel(isExpanse: false, numberOfPlatForm: min(3, index)))
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
    self.updateUIStartSearchingMode()
//    if self.topView.isHidden {
//      searchField.text = ""
//      self.showLoading()
//      self.viewModel.fetchDataFromAPI(query: "", orderBy: self.orderBy) { [weak self] in
//        self?.hideLoading()
//        self?.reloadUI()
//      }
//    } else {
//      self.updateUIStartSearchingMode()
//    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.updateUIEndSearchingMode()
  }

}

extension EarnListViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(EarnPoolViewCell.self, indexPath: indexPath)!
    let viewModel = dataSource[indexPath.row]
    cell.updateUI(viewModel: viewModel)
    return cell
  }
}

extension EarnListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var cellViewModel = dataSource[indexPath.row]
    cellViewModel.isExpanse = !cellViewModel.isExpanse
    self.tableView.beginUpdates()
    if let cell = self.tableView.cellForRow(at: indexPath) as? EarnPoolViewCell {
      animateCellHeight(cell: cell, viewModel: cellViewModel)
    }
    self.tableView.endUpdates()
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let cellViewModel = dataSource[indexPath.row]
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
    if let text = self.searchTextField.text {
//      self.showLoading()
//      self.viewModel.fetchDataFromAPI(query: text, orderBy: self.orderBy) {
//        self.hideLoading()
//        self.reloadUI()
//      }
    }
  }
}
