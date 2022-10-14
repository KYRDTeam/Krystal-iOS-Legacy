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
  let apiService = KrystalService()
  var currentAddress = AppDelegate.session.address
  
  var dataSource: Observable<[StakingPortfolioCellModel]> = .init([])
  var error: Observable<Error?> = .init(nil)
  var isLoading: Observable<Bool> = .init(false)
  
  func reloadDataSource() {
    dataSource.value.removeAll()
    guard let data = portfolio else {
      return
    }
    var output: [StakingPortfolioCellModel] = []
    data.pendingUnstakes?.forEach({ item in
      output.append(StakingPortfolioCellModel(pendingUnstake: item))
    })
    data.earningBalances.forEach { item in
      output.append(StakingPortfolioCellModel(earnBalance: item))
    }
    dataSource.value = output
  }
  
  func requestData() {
    isLoading.value = true
    apiService.getStakingPortfolio(address: currentAddress.addressString) { result in
      self.isLoading.value = false
      switch result {
      case .success(let portfolio):
        self.portfolio = portfolio
        self.reloadDataSource()
      case .failure(let error):
        self.error.value = error
      }
    }
  }
}

class StakingPortfolioViewController: InAppBrowsingViewController {
  @IBOutlet weak var portfolioTableView: UITableView!
  @IBOutlet weak var emptyViewContainer: UIView!
  
  let viewModel: StakingPortfolioViewModel = StakingPortfolioViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    registerCell()
    viewModel.dataSource.observeAndFire(on: self) { _ in
      self.portfolioTableView.reloadData()
      self.updateUIEmptyView()
    }
    viewModel.isLoading.observeAndFire(on: self) { status in
      if status {
        self.showLoadingHUD()
      } else {
        self.hideLoading()
      }
    }
    viewModel.requestData()
  }
  
  private func registerCell() {
    portfolioTableView.registerCellNib(StakingPortfolioCell.self)
  }
  
  private func updateUIEmptyView() {
    emptyViewContainer.isHidden = viewModel.dataSource.value.isNotEmpty
  }
}

extension StakingPortfolioViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.dataSource.value.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(StakingPortfolioCell.self, indexPath: indexPath)!
    let cm = viewModel.dataSource.value[indexPath.row]
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

extension StakingPortfolioViewController: StakingPortfolioCellDelegate {
  func warningButtonTapped() {
    self.showBottomBannerView(message: "It takes about x days to unstake. After that you can claim your rewards.")
  }
}
