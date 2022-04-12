//
//  GameTasksViewController.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import UIKit

class GameTasksViewController: BaseViewController {
  
  @IBOutlet weak var tableView: UITableView!
  
  var viewModel: GameTasksViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
  }
  
  func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    
    tableView.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 0, height: 8))
    tableView.registerCellNib(GameTaskCell.self)
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    viewModel.onTapBack?()
  }
}

extension GameTasksViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.tasks.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(GameTaskCell.self, indexPath: indexPath)!
    cell.configure(viewModel: GameTaskCellViewModel(task: viewModel.tasks[indexPath.row]))
    cell.selectionStyle = .none
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
}
