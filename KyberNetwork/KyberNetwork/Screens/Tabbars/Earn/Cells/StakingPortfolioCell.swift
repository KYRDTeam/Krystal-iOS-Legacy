//
//  StakingPortfolioCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/10/2022.
//

import UIKit
import BigInt

struct StakingPortfolioCellModel {
  let tokenLogo: String
  let chainLogo: UIImage?
  let platformLogo: String
  
  let displayAPYValue: String
  let displayDepositedValue: String
  let displayDeposited2Value: String
  let displayType: String
  let displayTokenName: String
  let displayPlatformName: String
  
  let isInProcess: Bool
  let isClaimable: Bool
  
  init(earnBalance: EarningBalance) {
    self.isInProcess = false
    self.tokenLogo = earnBalance.toUnderlyingToken.logo
    self.chainLogo = ChainType.make(chainID: earnBalance.chainID)?.chainIcon()
    self.platformLogo = earnBalance.platform.logo
    self.displayAPYValue = StringFormatter.percentString(value: earnBalance.apy)
    self.displayDepositedValue = (BigInt(earnBalance.stakingToken.balance)?.shortString(decimals: earnBalance.stakingToken.decimals) ?? "---") + " " + earnBalance.stakingToken.symbol
    self.displayDeposited2Value = (BigInt(earnBalance.toUnderlyingToken.balance)?.shortString(decimals: earnBalance.toUnderlyingToken.decimals) ?? "---") + " " + earnBalance.toUnderlyingToken.symbol
    self.displayType = "| " + earnBalance.platform.type.capitalized
    self.displayTokenName = earnBalance.toUnderlyingToken.symbol
    self.displayPlatformName = earnBalance.platform.name + " "
    self.isClaimable = false
  }
  
  init(pendingUnstake: StakingBalance) {
    self.isInProcess = true
    self.tokenLogo = pendingUnstake.logo
    self.chainLogo = ChainType.make(chainID: pendingUnstake.chainID ?? 1)?.chainIcon()
    self.platformLogo = pendingUnstake.platform?.logo ?? ""
    self.displayAPYValue = "---"
    self.displayDepositedValue = (BigInt(pendingUnstake.balance)?.shortString(decimals: pendingUnstake.decimals) ?? "---") + " " + pendingUnstake.symbol
    self.displayDeposited2Value = ""
    self.displayType = "| Stake"
    self.displayTokenName = pendingUnstake.symbol
    self.displayPlatformName = (pendingUnstake.platform?.name ?? "") + " "
    self.isClaimable = pendingUnstake.extraData?.status == "claimable"
  }
}

protocol StakingPortfolioCellDelegate: class {
  func warningButtonTapped()
}

class StakingPortfolioCell: UITableViewCell {
  @IBOutlet weak var tokenImageView: UIImageView!
  @IBOutlet weak var chainImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var platformImageView: UIImageView!
  
  @IBOutlet weak var platformNameLabel: UILabel!
  @IBOutlet weak var platformTypeLabel: UILabel!
  @IBOutlet weak var apyValueLabel: UILabel!
  @IBOutlet weak var depositedValueLabel: UILabel!
  @IBOutlet weak var deposited2ValueLabel: UILabel!
  
  @IBOutlet weak var processingStatusLabel: UILabel!
  @IBOutlet weak var warningIcon: UIImageView!
  @IBOutlet weak var warningButton: UIButton!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var minusButton: UIButton!
  @IBOutlet weak var warningLabelContainerView: UIView!
  @IBOutlet weak var claimButton: UIButton!
  @IBOutlet weak var depostTitleLabelLeadingContraintWithSuperView: NSLayoutConstraint!
  @IBOutlet weak var depositTitleLabelContraintWithAPYTitle: NSLayoutConstraint!
  @IBOutlet weak var apyTitleLabel: UILabel!
  
  weak var delegate: StakingPortfolioCellDelegate?
  
  func updateCellModel(_ model: StakingPortfolioCellModel) {
    if let url = URL(string: model.tokenLogo) {
      tokenImageView.setImage(with: url, placeholder: nil)
    }
    
    if let url = URL(string: model.platformLogo) {
      platformImageView.setImage(with: url, placeholder: nil)
    }
    
    chainImageView.image = model.chainLogo
    
    tokenNameLabel.text = model.displayTokenName
    platformNameLabel.text = model.displayPlatformName
    platformTypeLabel.text = model.displayType
    apyValueLabel.text = model.displayAPYValue
    depositedValueLabel.text = model.displayDepositedValue
    
    warningLabelContainerView.isHidden = !model.isInProcess || model.isClaimable
    claimButton.isHidden = !model.isClaimable
    
    addButton.isHidden = model.isInProcess
    minusButton.isHidden = model.isInProcess
    deposited2ValueLabel.text = model.displayDeposited2Value
    
    apyTitleLabel.isHidden = model.isInProcess
    apyValueLabel.isHidden = model.isInProcess
    
    depositTitleLabelContraintWithAPYTitle.priority = model.isInProcess ? UILayoutPriority(250) : UILayoutPriority(1000)
    depostTitleLabelLeadingContraintWithSuperView.priority = model.isInProcess ? UILayoutPriority(1000) : UILayoutPriority(250)
  }
  
  @IBAction func inProcessButtonTapped(_ sender: UIButton) {
    delegate?.warningButtonTapped()
  }
  
  @IBAction func claimButtonTapped(_ sender: UIButton) {
    //TODO: process next sprint
  }
}
