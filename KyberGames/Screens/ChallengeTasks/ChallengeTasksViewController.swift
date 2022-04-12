//
//  ChallengeTasksViewController.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import UIKit

class ChallengeTasksViewController: BaseViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  var viewModel: ChallengeTasksViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
  }
  
  func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    
    tableView.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 0, height: 8))
    tableView.registerCellNib(ChallengeTaskCell.self)
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    viewModel.onTapBack?()
  }
}

extension ChallengeTasksViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.tasks.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(ChallengeTaskCell.self, indexPath: indexPath)!
    cell.configure(task: viewModel.tasks[indexPath.row])
    cell.selectionStyle = .none
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
}
