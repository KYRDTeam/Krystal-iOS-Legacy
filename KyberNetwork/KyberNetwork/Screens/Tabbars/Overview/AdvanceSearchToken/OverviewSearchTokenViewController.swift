//
//  OverviewSearchTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/25/21.
//

import UIKit
import TagListView

//protocol OverviewSearchTokenViewControllerDelegate: class {
//  func overviewSearchTokenViewController(_ controller: OverviewSearchTokenViewController, open token: Token)
//}

class OverviewSearchTokenViewController: KNBaseViewController, AdvanceSearchTokenViewProtocol {
  var presenter: AdvanceSearchTokenPresenterProtocol!
  @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
  @IBOutlet weak var topView: UIView!
  @IBOutlet weak var topViewHeight: NSLayoutConstraint!
  @IBOutlet weak var searchField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var recentSearchTitle: UILabel!
  @IBOutlet weak var recentSearchTagList: TagListView!
  @IBOutlet weak var suggestSearchTItle: UILabel!
  @IBOutlet weak var suggestSearchTagList: TagListView!
  @IBOutlet weak var suggestSearchTitleTopContraint: NSLayoutConstraint!
  @IBOutlet weak var cancelButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: OverviewMainViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewMainViewCell.kCellID
    )
    self.recentSearchTagList.textFont = UIFont.Kyber.regular(with: 14)
    self.suggestSearchTagList.textFont = UIFont.Kyber.regular(with: 14)
    self.suggestSearchTagList.addTags(presenter.recommendTags)
    self.updateUIEmptyView()
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  func updateUIEmptyView() {
    if presenter.dataSource.isEmpty {
      self.emptyView.isHidden = false
      let recentTags = presenter.getRecentSearchTag()
      self.recentSearchTagList.removeAllTags()
      self.recentSearchTagList.addTags(recentTags)
      if recentTags.isEmpty {
        self.recentSearchTitle.isHidden = true
        self.recentSearchTagList.isHidden = true
        self.suggestSearchTitleTopContraint.constant = 10.0
      } else {
        self.recentSearchTitle.isHidden = false
        self.recentSearchTagList.isHidden = false
        self.suggestSearchTitleTopContraint.constant = 180.0
      }
    } else {
      self.emptyView.isHidden = true
    }
  }
  
  func updateUIStartSearchingMode() {
    self.view.layoutIfNeeded()
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      self.searchViewRightConstraint.constant = 77
      self.topViewHeight.constant = 0
      self.topView.isHidden = true
      self.cancelButton.isHidden = false
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
      self.view.layoutIfNeeded()
    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: Any) {
    self.searchField.resignFirstResponder()
    self.updateUIEndSearchingMode()
  }

}

extension OverviewSearchTokenViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return presenter.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewMainViewCell.kCellID,
      for: indexPath
    ) as! OverviewMainViewCell
    
    let cellModel = presenter.dataSource[indexPath.row]
    cell.updateCell(cellModel)
    return cell
  }
}

extension OverviewSearchTokenViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellModel = presenter.dataSource[indexPath.row]
    switch cellModel.mode {
    case .search(token: let token):
      presenter.openChartToken(token: token)
      presenter.saveNewSearchTag(token.symbol)
    default:
      break
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return OverviewMainViewCell.kCellHeight
  }
}

extension OverviewSearchTokenViewController: UITextFieldDelegate {
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    self.updateUIStartSearchingMode()
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateUIEndSearchingMode()
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    presenter.searchText = text
    presenter.reloadAllData()
    self.tableView.reloadData()
    self.updateUIEmptyView()
    return true
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return false
  }
}

extension OverviewSearchTokenViewController: TagListViewDelegate {
  func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
    let tokens = KNSupportedTokenStorage.shared.allActiveTokens
    if let found = tokens.first(where: { (token) -> Bool in
      return token.symbol.lowercased() == title.lowercased()
    }) {
      presenter.openChartToken(token: found)
    }
  }
}
