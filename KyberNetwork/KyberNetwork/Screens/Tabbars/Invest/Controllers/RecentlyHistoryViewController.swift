//
//  RecentlyHistoryViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 31/12/2021.
//

import UIKit

class RecentlyHistoryViewModel {
  var dataSource: [BrowserCellViewModel]
  init() {
    self.dataSource = BrowserStorage.shared.recentlyBrowser.map({ item in
      return BrowserCellViewModel(item: item)
    })
  }
}

class RecentlyHistoryViewController: UIViewController {
  
  @IBOutlet weak var historyTableView: UITableView!
  let viewModel: RecentlyHistoryViewModel = RecentlyHistoryViewModel()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: BrowserCell.className, bundle: nil)
    self.historyTableView.register(nib, forCellReuseIdentifier: BrowserCell.cellID)
    self.historyTableView.rowHeight = BrowserCell.cellHeight
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func clearButtonTapped(_ sender: UIButton) {
    
  }
  
}

extension RecentlyHistoryViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: BrowserCell.cellID,
      for: indexPath
    ) as! BrowserCell
    let cellModel = self.viewModel.dataSource[indexPath.row]
    cell.setUpUI(viewModel: cellModel)
    return cell
  }
}
