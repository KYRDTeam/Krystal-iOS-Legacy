//
//  RewardsViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 11/10/2021.
//

import UIKit
import BigInt
import KrystalWallets
import AppState
import BaseModule

class RewardsViewControllerViewModel {
  
  var address: KAddress {
    return AppDelegate.session.address
  }
  
  var rewardDataSource: [KNRewardModel] = []
  var rewardDetailDataSource: [KNRewardModel] = []
  var rewardDetailDisplayDataSource: [KNRewardModel] = []
  var isShowingDetails = true {
    didSet {
      updateFilterDataSourceIfNeed()
    }
  }
  var shouldDisableClaim = false
  var supportedChains: [Int] = []
  
  
  func totalBalanceString() -> String {
    guard let model = rewardDataSource.first else {
      return "--/--"
    }
    return "+ " + StringFormatter.amountString(value: model.amount) + " " + model.rewardSymbol
  }
  func updateFilterDataSourceIfNeed() {
    if rewardDataSource.isEmpty {
      return
    }
    if isShowingDetails {
      self.rewardDetailDisplayDataSource = self.rewardDetailDataSource
    } else {
      self.rewardDetailDisplayDataSource = self.rewardDetailDataSource.filter({ rewardModel in
        return rewardModel.status.lowercased() != "claimed"
      })
    }
  }

  func numberOfRows(section: Int) -> Int {
    if section == 0 {
      return rewardDataSource.isEmpty ? 0 : rewardDataSource.count + 1
    } else {
      return rewardDetailDisplayDataSource.isEmpty ? 0 : rewardDataSource.isEmpty ? rewardDetailDisplayDataSource.count : rewardDetailDisplayDataSource.count + 1
    }
  }
  
  func dataModelAtIndex(_ indexPath: IndexPath) -> KNRewardModel {
    if indexPath.section == 0 {
      return rewardDataSource[indexPath.row]
    } else {
      let index = rewardDataSource.isEmpty ? indexPath.row : indexPath.row - 1
      return rewardDetailDisplayDataSource[index]
    }
  }
    
    func buildExtraData() -> [String: String] {
        return [
            "token": rewardDataSource.first?.symbol ?? "",
            "amount": "\(rewardDataSource.first?.amount ?? 0)",
            "amountUsd": "\(rewardDataSource.first?.value ?? 0)"
        ]
    }
}

protocol RewardsViewControllerDelegate: class {
  func reloadData(_ controller: RewardsViewController)
  func loadClaimRewards(_ controller: RewardsViewController)
  func showClaimRewardVC(_ controller: RewardsViewController, model: KNRewardModel, txObject: TxObject)
}

class RewardsViewController: BaseWalletOrientedViewController {
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var emptyButton: UIButton!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var emptyLabel: UILabel!

  weak var delegate: RewardsViewControllerDelegate?
  let viewModel: RewardsViewControllerViewModel = RewardsViewControllerViewModel()

  override func viewDidLoad() {
    super.viewDidLoad()
    configUI()
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if viewModel.address.isWatchWallet {
      emptyView.isHidden = false
      emptyLabel.text = "You are using watch wallet".toBeLocalised()
      emptyButton.isHidden = true
    } else {
      emptyButton.isHidden = false
      emptyLabel.text = "You don't have any reward".toBeLocalised()
    }
  }
  
  override func onAppSwitchAddress() {
    self.delegate?.reloadData(self)
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
    emptyView.isHidden = !(self.viewModel.rewardDataSource.isEmpty && self.viewModel.rewardDetailDisplayDataSource.isEmpty)
    self.tableView.reloadData()
  }

  @IBAction func emptyButtonTapped(_ sender: Any) {
    //move to trade screen
    self.navigationController?.tabBarController?.selectedIndex = 1
  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  func coordinatorDidUpdateRewards(rewards: [KNRewardModel], rewardDetails: [KNRewardModel], supportedChain: [Int]) {
    self.viewModel.rewardDataSource = rewards
    self.viewModel.rewardDetailDataSource = rewardDetails
    self.viewModel.rewardDetailDisplayDataSource = rewardDetails
    self.viewModel.updateFilterDataSourceIfNeed()
    self.viewModel.supportedChains = supportedChain
    self.updateUI()
  }
  
  func coordinatorDidUpdateClaimRewards(_ shouldShowPopup: Bool, txObject: TxObject) {
    if shouldShowPopup, let model = self.viewModel.rewardDataSource.first {
      self.delegate?.showClaimRewardVC(self, model: model, txObject: txObject)
    }
  }

  func claimRewardsButtonTapped() {
    Tracker.track(event: .promotionClaim)
      
    // check current chain is in supported chain or not ? if not then show popup switch chain
    if !self.viewModel.supportedChains.contains(KNGeneralProvider.shared.customRPC.chainID) {
      let alertController = KNPrettyAlertController(
        title: "",
        message: Strings.switchToBSCToClaimRewards,
        secondButtonTitle: Strings.ok,
        firstButtonTitle: Strings.cancel,
        secondButtonAction: {
            AppState.shared.updateChain(chain: .bsc)
            self.claimRewards()
        },
        firstButtonAction: nil
      )
      alertController.popupHeight = 220
      self.present(alertController, animated: true, completion: nil)
    } else {
      claimRewards()
      MixPanelManager.track("reward_swap", properties: ["screenid": "reward"])
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
    cell.selectionStyle = .none
    cell.shouldRoundTopBGView = indexPath.row == 0
    cell.updateCell(model: self.viewModel.dataModelAtIndex(indexPath))
    return cell
  }

  func claimButtonCell() -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: ClaimButtonTableViewCell.kCellID
    ) as! ClaimButtonTableViewCell
    cell.setClaimButtonState(isEnabled: !self.viewModel.shouldDisableClaim)
    cell.onClaimButtonTapped = {
      self.claimRewardsButtonTapped()
    }
    cell.selectionStyle = .none
    return cell
  }

  func toggleRewardDetailCell() -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: ToggleTokenCell.kCellID
    ) as! ToggleTokenCell
    cell.onValueChanged = { isOn in
      self.viewModel.isShowingDetails = !isOn
      self.updateUI()
    }
    cell.selectionStyle = .none
    return cell
  }

  func rewardDetailCell(_ indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: RewardDetailCell.kCellID,
      for: indexPath
    ) as! RewardDetailCell
    cell.selectionStyle = .none
    cell.updateCell(model: self.viewModel.dataModelAtIndex(indexPath))
    cell.contentView.backgroundColor = indexPath.row % 2 == 0 ? UIColor(named: "mainViewBgColor") : UIColor(named: "buttonTextColor")
    return cell
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      return indexPath.row == self.viewModel.rewardDataSource.count ? claimButtonCell() : rewardCell(indexPath)
    } else {
      if self.viewModel.rewardDataSource.isEmpty {
        return rewardDetailCell(indexPath)
      } else {
        return indexPath.row == 0 ? toggleRewardDetailCell() : rewardDetailCell(indexPath)
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRows(section: section)
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
}
