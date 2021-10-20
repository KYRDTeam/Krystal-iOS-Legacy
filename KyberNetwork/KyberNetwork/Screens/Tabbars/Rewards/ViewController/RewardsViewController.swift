//
//  RewardsViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 11/10/2021.
//

import UIKit
import BigInt

class RewardsViewControllerViewModel {
  var rewardDataSource: [KNRewardModel] = []
  var rewardDetailDataSource: [KNRewardModel] = []
  var isShowingDetails = true
  var supportedChains: [Int] = []

  func numberOfRows(section: Int) -> Int {
    if section == 0 {
      return rewardDataSource.isEmpty ? 0 : rewardDataSource.count + 1
    } else if isShowingDetails {
      return rewardDetailDataSource.isEmpty ? 0 : rewardDetailDataSource.count + 1
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

protocol RewardsViewControllerDelegate: class {
  func loadClaimRewards(_ controller: RewardsViewController)
  func showClaimRewardVC(_ controller: RewardsViewController, model: KNRewardModel, txObject: TxObject)
}


class RewardsViewController: KNBaseViewController {
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var emptyButton: UIButton!
  @IBOutlet weak var tableView: UITableView!
  var delegate: RewardsViewControllerDelegate?
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
    emptyView.isHidden = !(self.viewModel.rewardDataSource.isEmpty && self.viewModel.rewardDetailDataSource.isEmpty)
    self.tableView.reloadData()
  }

  @IBAction func emptyButtonTapped(_ sender: Any) {

  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  func coordinatorDidUpdateRewards(rewards: [KNRewardModel], rewardDetails: [KNRewardModel], supportedChain: [Int]) {
    self.viewModel.rewardDataSource = rewards
    self.viewModel.rewardDetailDataSource = rewardDetails
    self.viewModel.supportedChains = supportedChain
    self.updateUI()
  }
  
  func coordinatorDidUpdateClaimRewards(_ shouldShowPopup: Bool, txObject: TxObject) {
    if shouldShowPopup, let model = self.viewModel.rewardDataSource.first {
      self.delegate?.showClaimRewardVC(self, model: model, txObject: txObject)
    }
  }

  func claimRewardsButtonTapped() {
    // check current chain is in supported chain or not ? if not then show popup switch chain
    if !self.viewModel.supportedChains.contains(KNGeneralProvider.shared.customRPC.chainID) {
      let popup = SwitchChainViewController()
      popup.completionHandler = { selected in
        KNGeneralProvider.shared.currentChain = selected
        self.claimRewards()
      }
      self.present(popup, animated: true, completion: nil)
    } else {
      claimRewards()
    }
  }
  
  func claimRewards() {
    self.delegate?.loadClaimRewards(self)
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
    cell.onClaimButtonTapped = {
      self.claimRewardsButtonTapped()
    }
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
