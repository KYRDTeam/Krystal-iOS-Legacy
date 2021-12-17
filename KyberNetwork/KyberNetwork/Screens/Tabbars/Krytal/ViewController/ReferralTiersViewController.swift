//
//  ReferralTiersViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 15/12/2021.
//

import UIKit

class ReferralTiersViewModel {
  let tiers: [Tier]
  init(tiers: [Tier]) {
    self.tiers = tiers
  }
  
  func numberOfRows() -> Int {
    return tiers.count
  }
}

class ReferralTiersViewController: KNBaseViewController {
  let transitor = TransitionDelegate()
  fileprivate let kReferralTiersCellID: String = "ReferralTiersCell"
  fileprivate let kReferralTiersCellHeight: CGFloat = 32.0
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var topBackgroundView: UIView!

  let viewModel: ReferralTiersViewModel

  init(viewModel: ReferralTiersViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ReferralTiersViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    self.configUI()
  }
  
  func configUI() {
    let nib = UINib(nibName: ReferralTiersCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: kReferralTiersCellID)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    topBackgroundView.addGestureRecognizer(tapGesture)
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }
}

extension ReferralTiersViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRows()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kReferralTiersCellID, for: indexPath) as! ReferralTiersCell
    let tier = self.viewModel.tiers[indexPath.row]
    cell.levelLabel.text = "\(tier.level)"
    cell.volumeLabel.text = StringFormatter.usdString(value: tier.volume)
    cell.rewardLabel.text = StringFormatter.usdString(value: tier.reward)
    return cell
  }
}

extension ReferralTiersViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return kReferralTiersCellHeight
  }
}

extension ReferralTiersViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 426//self.viewModel.walletTableViewHeight + 179
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
