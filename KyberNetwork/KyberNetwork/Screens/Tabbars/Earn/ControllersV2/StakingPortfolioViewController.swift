//
//  StakingPortfolioViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/10/2022.
//

import UIKit
import StackViewController

class StakingPortfolioViewModel {
  var portfolio: PortfolioStaking?
  
  var dataSource: [StakingPortfolioCellModel] = []
  
  func reloadDataSource() {
    dataSource.removeAll()
    guard let data = portfolio else {
      return
    }
    data.pendingUnstakes?.forEach({ item in
      dataSource.append(StakingPortfolioCellModel(pendingUnstake: item))
    })
    data.earningBalances.forEach { item in
      dataSource.append(StakingPortfolioCellModel(earnBalance: item))
    }
    
  }
}

class StakingPortfolioViewController: InAppBrowsingViewController {
  @IBOutlet weak var portfolioTableView: UITableView!
  
  let viewModel: StakingPortfolioViewModel = StakingPortfolioViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    registerCell()
  }
  
  private func registerCell() {
    portfolioTableView.registerCellNib(StakingPortfolioCell.self)
  }
  
}

extension StakingPortfolioViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(StakingPortfolioCell.self, indexPath: indexPath)!
    let cm = viewModel.dataSource[indexPath.row]
    cell.updateCellModel(cm)
    return cell
  }
}

extension StakingPortfolioViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 178
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
  }
}
