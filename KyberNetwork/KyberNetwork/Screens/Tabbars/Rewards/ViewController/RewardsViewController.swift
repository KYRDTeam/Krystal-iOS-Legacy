//
//  RewardsViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 11/10/2021.
//

import UIKit

class RewardsViewControllerViewModel {
  var rewardDataSource: [KNRewardModel] = []
  var rewardDetailDataSource: [KNRewardModel] = []
  var isShowingDetails = true
  
  func numberOfRows(section: Int) -> Int {
    if section == 0 {
      return rewardDataSource.count + 1
    } else if isShowingDetails {
      return rewardDetailDataSource.count + 1
    } else {
      return 1
    }
  }
  
  func dataModelAtIndex(_ indexPath: IndexPath) -> KNRewardModel {
    if indexPath.section == 0 {
      return rewardDataSource[indexPath.row]
    } else {
      return rewardDetailDataSource[indexPath.row - 1]
    }
  }
}


class RewardsViewController: KNBaseViewController {

  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var emptyButton: UIButton!
  @IBOutlet weak var tableView: UITableView!
  let viewModel: RewardsViewControllerViewModel = RewardsViewControllerViewModel()
  override func viewDidLoad() {
    super.viewDidLoad()
    configUI()
  }

  func configUI() {
    emptyButton.rounded(color: UIColor(named: "normalTextColor")!, width: 1, radius: 16)
    
    var nib = UINib(nibName: RewardTableViewCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: RewardTableViewCell.kCellID)
    
    nib = UINib(nibName: ClaimButtonTableViewCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: ClaimButtonTableViewCell.kCellID)
    
    nib = UINib(nibName: ToggleTokenCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: ToggleTokenCell.kCellID)
    
    nib = UINib(nibName: RewardDetailCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: RewardDetailCell.kCellID)
  }
  
  func updateUI() {
    emptyView.isHidden = !self.viewModel.rewardDataSource.isEmpty
    self.tableView.reloadData()
  }

  @IBAction func emptyButtonTapped(_ sender: Any) {

  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  func coordinatorDidUpdateRewards(rewards: [KNRewardModel], rewardDetails: [KNRewardModel]) {
    self.viewModel.rewardDataSource = rewards
    self.viewModel.rewardDetailDataSource = rewardDetails
    self.updateUI()
  }
}

extension RewardsViewController: UITableViewDelegate {
  
}

extension RewardsViewController: UITableViewDataSource {
  
  func rewardCell(_ indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: RewardTableViewCell.kCellID,
      for: indexPath
    ) as! RewardTableViewCell
    cell.shouldRoundTopBGView = indexPath.row == 0
    cell.updateCell(model: self.viewModel.dataModelAtIndex(indexPath))
    return cell
  }
  
  func claimButtonCell() -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: ClaimButtonTableViewCell.kCellID
    ) as! ClaimButtonTableViewCell
    return cell
  }
  
  func toggleRewardDetailCell() -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: ToggleTokenCell.kCellID
    ) as! ToggleTokenCell
    cell.onValueChanged = { isOn in
      self.viewModel.isShowingDetails = isOn
      self.updateUI()
    }
    return cell
  }
  
  func rewardDetailCell(_ indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: RewardDetailCell.kCellID,
      for: indexPath
    ) as! RewardDetailCell
    cell.updateCell(model: self.viewModel.dataModelAtIndex(indexPath))
    return cell
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      return indexPath.row == self.viewModel.rewardDataSource.count ? claimButtonCell() : rewardCell(indexPath)
    } else {
      return indexPath.row == 0 ? toggleRewardDetailCell() : rewardDetailCell(indexPath)
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRows(section: section)
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
}
