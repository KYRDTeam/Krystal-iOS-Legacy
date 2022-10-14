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
  let displayType: String
  let displayTokenName: String
  let displayPlatformName: String
  
  let isInProcess: Bool
  
  init(earnBalance: EarningBalance) {
    self.isInProcess = false
    self.tokenLogo = earnBalance.toUnderlyingToken.logo
    self.chainLogo = ChainType.make(chainID: earnBalance.chainID)?.chainIcon()
    self.platformLogo = earnBalance.platform.logo
    self.displayAPYValue = StringFormatter.percentString(value: earnBalance.apy) + "%"
    self.displayDepositedValue = (BigInt(earnBalance.toUnderlyingToken.balance)?.shortString(decimals: earnBalance.toUnderlyingToken.decimals) ?? "---") + " " + earnBalance.toUnderlyingToken.symbol
    self.displayType = "| " + earnBalance.platform.type.capitalized
    self.displayTokenName = earnBalance.toUnderlyingToken.symbol
    self.displayPlatformName = earnBalance.platform.name
  }
  
  init(pendingUnstake: StakingBalance) {
    self.isInProcess = true
    self.tokenLogo = pendingUnstake.logo
    self.chainLogo = ChainType.make(chainID: pendingUnstake.chainID ?? 1)?.chainIcon()
    self.platformLogo = pendingUnstake.platform?.logo ?? ""
    self.displayAPYValue = "---"
    self.displayDepositedValue = (BigInt(pendingUnstake.balance)?.shortString(decimals: pendingUnstake.decimals) ?? "---") + " " + pendingUnstake.symbol
    
    self.displayType = "| Stake"
    self.displayTokenName = pendingUnstake.symbol
    self.displayPlatformName = pendingUnstake.platform?.name ?? ""
  }
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
  
  @IBOutlet weak var processingStatusLabel: UILabel!
  
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
  }
}
