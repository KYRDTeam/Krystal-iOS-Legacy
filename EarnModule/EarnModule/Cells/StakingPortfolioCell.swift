//
//  StakingPortfolioCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/10/2022.
//

import UIKit
import BigInt
import Utilities
import Services
import SwipeCellKit

internal enum EarnWarningType {
    case disable
    case warning
    case none
}

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
    let hasRewardApy: Bool
  var pendingUnstake: PendingUnstake?
  var earnBalance: EarningBalance?
    let displayStatusLogo: UIImage?
    let warningType: EarnWarningType
  
  init(earnBalance: EarningBalance) {
    self.earnBalance = earnBalance
    self.isInProcess = false
    self.tokenLogo = earnBalance.toUnderlyingToken.logo
    self.chainLogo = ChainType.make(chainID: earnBalance.chainID)?.chainIcon()
    self.platformLogo = earnBalance.platform.logo
    self.displayAPYValue = StringFormatter.percentString(value: earnBalance.apy / 100)

    var stakingBalanceString = (BigInt(earnBalance.stakingToken.balance)?.shortString(decimals: earnBalance.stakingToken.decimals) ?? "---") + " " + earnBalance.stakingToken.symbol
    var toUnderlyingBalanceString = (BigInt(earnBalance.toUnderlyingToken.balance)?.shortString(decimals: earnBalance.toUnderlyingToken.decimals) ?? "---") + " " + earnBalance.toUnderlyingToken.symbol

    if let stakingBalanceBigInt = BigInt(earnBalance.stakingToken.balance), let toUnderlyingBalanceBigInt = BigInt(earnBalance.toUnderlyingToken.balance) {
      if toUnderlyingBalanceBigInt < BigInt(pow(10.0, Double(earnBalance.toUnderlyingToken.decimals - 6))) {
        toUnderlyingBalanceString = "< 0.000001 \(earnBalance.toUnderlyingToken.symbol)"
      }
      if stakingBalanceBigInt < BigInt(pow(10.0, Double(earnBalance.stakingToken.decimals - 6))) {
          stakingBalanceString = "< 0.000001 \(earnBalance.stakingToken.symbol)"
      }
      if stakingBalanceBigInt > BigInt(0) {
        let usdBigIntValue = BigInt(earnBalance.underlyingUsd * pow(10.0 , Double(earnBalance.toUnderlyingToken.decimals))) * toUnderlyingBalanceBigInt / BigInt(pow(10.0 , Double(earnBalance.toUnderlyingToken.decimals)))
        let usdString = usdBigIntValue < BigInt(pow(10.0, Double(earnBalance.toUnderlyingToken.decimals - 2))) ? " | < $0.01" : " | $\(usdBigIntValue.shortString(decimals: earnBalance.toUnderlyingToken.decimals, maxFractionDigits: 2))"
        stakingBalanceString = stakingBalanceString + usdString
      }
    }

    self.displayDepositedValue = toUnderlyingBalanceString
    self.displayDeposited2Value = stakingBalanceString
    self.displayType = "| " + earnBalance.platform.type.capitalized
    self.displayTokenName = earnBalance.toUnderlyingToken.symbol
    self.displayPlatformName = earnBalance.platform.name.uppercased()
    self.isClaimable = false
      switch earnBalance.status.value.lowercased() {
      case "disabled":
          self.displayStatusLogo = UIImage(imageName: "stake_disable_icon")
          self.warningType = .disable
      case "warning":
          self.displayStatusLogo = UIImage(imageName: "stake_warning_icon")
          self.warningType = .warning
      default:
          self.displayStatusLogo = nil
          self.warningType = .none
      }
	self.hasRewardApy = earnBalance.rewardApy > 0
  }
  
  init(pendingUnstake: PendingUnstake) {
      self.pendingUnstake = pendingUnstake
    self.isInProcess = true
    self.tokenLogo = pendingUnstake.logo
    self.chainLogo = ChainType.make(chainID: pendingUnstake.chainID)?.chainIcon()
    self.platformLogo = pendingUnstake.platform.logo
    self.displayAPYValue = "---"
    self.displayDepositedValue = (BigInt(pendingUnstake.balance)?.shortString(decimals: pendingUnstake.decimals) ?? "---") + " " + pendingUnstake.symbol
    let balanceBigInt = BigInt(pendingUnstake.balance) ?? BigInt(0)
    let usdBigIntValue = BigInt(pendingUnstake.priceUsd * pow(10.0 , Double(pendingUnstake.decimals))) * balanceBigInt / BigInt(pow(10.0 , Double(pendingUnstake.decimals)))
    self.displayDeposited2Value = "$\(usdBigIntValue.shortString(decimals: pendingUnstake.decimals, maxFractionDigits: 2))"
    self.displayType = "| " + pendingUnstake.platform.type.capitalized
    self.displayTokenName = pendingUnstake.symbol
    self.displayPlatformName = pendingUnstake.platform.name.uppercased()
    self.isClaimable = pendingUnstake.extraData.status == "claimable"
      self.warningType = .none
      self.displayStatusLogo = nil
	self.hasRewardApy = false
  }
    
    func timeForUnstakeString() -> String {
        let isAnkr = displayPlatformName.uppercased() == "ANKR"
        let isLido = displayPlatformName.uppercased() == "LIDO"
        var time = ""
        if displayTokenName.uppercased() == "AVAX".lowercased() && isAnkr {
            time = Strings.avaxUnstakeTime
        } else if displayTokenName.uppercased() == "BNB" && isAnkr {
            time = Strings.bnbUnstakeTime
        } else if displayTokenName.uppercased() == "FTM" && isAnkr {
            time = Strings.ftmUnstakeTime
        } else if displayTokenName.uppercased() == "MATIC" && isAnkr {
            time = Strings.maticUnstakeTime
        } else if displayTokenName.uppercased() == "SOL" && isLido {
            time = Strings.solUnstakeTime
        }
        return String(format: Strings.itTakeAboutXDaysToUnstake, time)
    }
}

class StakingPortfolioCell: SwipeTableViewCell {
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
  @IBOutlet weak var balanceTitleLabel: UILabel!
  @IBOutlet weak var depositedValueLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusImageView: UIImageView!
	@IBOutlet weak var rewardApyIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        statusImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showWarningPopup))
        statusImageView.addGestureRecognizer(tapGesture)
		rewardApyIcon.isUserInteractionEnabled = true
        rewardApyIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRewardApyIcon)))
    }
    
    var onTapHint: (() -> Void)? = nil
  var claimTapped: (() -> ())?
    var onTapWarningIcon: ((EarnWarningType) -> Void)?
    var onTapRewardApy: ((EarningBalance) -> Void)?
    var cellModel: StakingPortfolioCellModel?
  
  func updateCellModel(_ model: StakingPortfolioCellModel) {
    tokenImageView.loadImage(model.tokenLogo)
    platformImageView.loadImage(model.platformLogo)
    chainImageView.image = model.chainLogo
    tokenNameLabel.text = model.displayTokenName
    platformNameLabel.text = model.displayPlatformName
    platformTypeLabel.text = model.displayType
    apyValueLabel.text = model.displayAPYValue
    depositedValueLabel.text = model.displayDepositedValue
    
    warningLabelContainerView.isHidden = !model.isInProcess || model.isClaimable
    claimButton.isHidden = !model.isClaimable
    depositedValueLabelTopConstraint.constant = model.isInProcess ? 10 : 30
    warningButtonHeightConstraint.constant = model.isInProcess ? 30 : 0
    addButton.isHidden = model.isInProcess
    minusButton.isHidden = model.isInProcess
    deposited2ValueLabel.text = model.displayDeposited2Value
    
    apyTitleLabel.isHidden = model.isInProcess
    balanceTitleLabel.isHidden = model.isInProcess
    apyValueLabel.isHidden = model.isInProcess
    
    depositTitleLabelContraintWithAPYTitle.priority = model.isInProcess ? UILayoutPriority(250) : UILayoutPriority(999)
    depostTitleLabelLeadingContraintWithSuperView.priority = model.isInProcess ? UILayoutPriority(999) : UILayoutPriority(250)
      if let warningIconImg = model.displayStatusLogo {
          statusImageView.isHidden = false
          statusImageView.image = warningIconImg
      } else {
          statusImageView.isHidden = true
      }
      rewardApyIcon.isHidden = !model.hasRewardApy
      cellModel = model
  }
  
  @IBAction func inProcessButtonTapped(_ sender: UIButton) {
      if let onTapHint = onTapHint {
          onTapHint()
      }
  }
  
  @IBAction func claimButtonTapped(_ sender: UIButton) {
      claimTapped?()
  }
    
    @objc func showWarningPopup() {
        guard let cellModel = cellModel else {
            return
        }
        onTapWarningIcon?(cellModel.warningType)
    }

	@objc func tapRewardApyIcon() {
        guard let earningBalance = cellModel?.earnBalance else {
            return
        }
        onTapRewardApy?(earningBalance)
        
    }
}
