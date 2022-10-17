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
  
  var dataSource: Observable<([StakingPortfolioCellModel], [StakingPortfolioCellModel])> = .init(([], []))
  var error: Observable<Error?> = .init(nil)
  var isLoading: Observable<Bool> = .init(false)
  
  fileprivate func cleanAllData() {
    dataSource.value.0.removeAll()
    dataSource.value.1.removeAll()
  }
  
  fileprivate func isEmpty() -> Bool {
    return dataSource.value.0.isEmpty && dataSource.value.1.isEmpty
  }
  
  func reloadDataSource() {
    cleanAllData()
    guard let data = portfolio else {
      return
    }
    var output: [StakingPortfolioCellModel] = []
    var pending: [StakingPortfolioCellModel] = []
    data.pendingUnstakes.forEach({ item in
      pending.append(StakingPortfolioCellModel(pendingUnstake: item))
    })
    data.earningBalances.forEach { item in
      output.append(StakingPortfolioCellModel(earnBalance: item))
    }
    dataSource.value = (output, pending)
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
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if viewModel.isEmpty() {
      viewModel.requestData()
    }
  }
  
  private func registerCell() {
    portfolioTableView.registerCellNib(StakingPortfolioCell.self)
  }
  
  private func updateUIEmptyView() {
    emptyViewContainer.isHidden = !viewModel.isEmpty()
  }
}

extension StakingPortfolioViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return viewModel.dataSource.value.1.isEmpty ? 1 : 2
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? viewModel.dataSource.value.0.count : viewModel.dataSource.value.1.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(StakingPortfolioCell.self, indexPath: indexPath)!
    let items = indexPath.section == 0 ? viewModel.dataSource.value.0 : viewModel.dataSource.value.1
    let cm = items[indexPath.row]
    cell.updateCellModel(cm)
    cell.delegate = self
    return cell
  }
}

extension StakingPortfolioViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: 100, height: 40))
    titleLabel.center.y = view.center.y
    titleLabel.text = section == 0 ? "STAKING" : "UNSTAKING"
    titleLabel.font = UIFont.Kyber.regular(with: 14)
    titleLabel.textColor = UIColor(named: "textWhiteColor")
    view.addSubview(titleLabel)
    
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 140
  }
}

extension StakingPortfolioViewController: StakingPortfolioCellDelegate {
  func warningButtonTapped() {
    self.showBottomBannerView(message: "It takes about x days to unstake. After that you can claim your rewards.")
  }
}
