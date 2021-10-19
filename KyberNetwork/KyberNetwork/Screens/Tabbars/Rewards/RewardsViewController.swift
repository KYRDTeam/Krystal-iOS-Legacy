//
//  RewardsViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 11/10/2021.
//

import UIKit

class RewardsViewController: KNBaseViewController {

  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var emptyButton: UIButton!
  @IBOutlet weak var tableView: UITableView!

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
    
    emptyView.isHidden = true
  }

  @IBAction func emptyButtonTapped(_ sender: Any) {

  }

  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension RewardsViewController: UITableViewDelegate {
  
}

extension RewardsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row <= 1 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: RewardTableViewCell.kCellID,
        for: indexPath
      ) as! RewardTableViewCell
      cell.shouldRoundTopBGView = indexPath.row == 0
      return cell
    } else if indexPath.row == 2 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: ClaimButtonTableViewCell.kCellID,
        for: indexPath
      ) as! ClaimButtonTableViewCell
      return cell
    } else if indexPath.row == 3 {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: ToggleTokenCell.kCellID,
        for: indexPath
      ) as! ToggleTokenCell
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: RewardDetailCell.kCellID,
        for: indexPath
      ) as! RewardDetailCell
      return cell
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 8
  }


}
