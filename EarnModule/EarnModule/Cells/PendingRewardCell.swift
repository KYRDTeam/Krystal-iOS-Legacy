//
//  PendingRewardCell.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 11/12/2022.
//

import UIKit
import DesignSystem
import Services
import BigInt

struct PendingRewardCellModel {
    let tokenLogo: String
    let chainLogo: String
    let platformLogo: String
    
    let displayType: String
    let displayTokenName: String
    let displayPlatformName: String
    
    let displayClaimAmount: String
    let displayClaimValue: String
    
    let rewardItem: RewardItem
    
    init(item: RewardItem) {
        self.tokenLogo = item.rewardToken.tokenInfo.logo
        self.chainLogo = item.chain.logo
        self.platformLogo = item.platform.logo
        
        self.displayType = "| " + item.platform.earningType.capitalized
        self.displayTokenName = item.rewardToken.tokenInfo.name
        self.displayPlatformName = item.platform.name.uppercased()
        let amountBigInt = BigInt(item.rewardToken.pendingReward.balance) ?? .zero
        if amountBigInt < BigInt(pow(10.0, Double(item.rewardToken.tokenInfo.decimals))) {
            self.displayClaimAmount =  "< 0.000001 " + item.rewardToken.tokenInfo.symbol
        } else {
            self.displayClaimAmount = (amountBigInt.shortString(decimals: item.rewardToken.tokenInfo.decimals)) + " " + item.rewardToken.tokenInfo.symbol
        }
        
        let usdBigIntValue = BigInt(item.rewardToken.pendingReward.balancePriceUsd * pow(10.0 , Double(item.rewardToken.tokenInfo.decimals))) * amountBigInt / BigInt(pow(10.0 , Double(item.rewardToken.tokenInfo.decimals)))
        self.displayClaimValue = "$\(usdBigIntValue.shortString(decimals: item.rewardToken.tokenInfo.decimals))"
        self.rewardItem = item
    }
}

class PendingRewardCell: UITableViewCell {
    
    @IBOutlet weak var tokenImageView: UIImageView!
    @IBOutlet weak var chainImageView: UIImageView!
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var platformImageView: UIImageView!
    
    @IBOutlet weak var platformNameLabel: UILabel!
    @IBOutlet weak var platformTypeLabel: UILabel!
    
    @IBOutlet weak var rewardAmountLabel: UILabel!
    @IBOutlet weak var rewardValueLabel: UILabel!
    
    @IBOutlet weak var claimButton: UIButton!
    
    var cellModel: PendingRewardCellModel?
    var onTap: ((PendingRewardCellModel) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        claimButton.rounded(color: AppTheme.current.primaryColor, width: 1, radius: 12)
    }
    
    func updateCellModel(_ model: PendingRewardCellModel) {
        tokenImageView.loadImage(model.tokenLogo)
        chainImageView.loadImage(model.chainLogo)
        tokenNameLabel.text = model.displayTokenName
        platformImageView.loadImage(model.platformLogo)
        platformNameLabel.text = model.displayPlatformName
        platformTypeLabel.text = model.displayType
        rewardAmountLabel.text = model.displayClaimAmount
        rewardValueLabel.text = model.displayClaimValue
        cellModel = model
    }
    
    @IBAction func tapClaimButton(_ sender: UIButton) {
        guard let cellModel = cellModel else {
            return
        }
        onTap?(cellModel)
    }
    
}
