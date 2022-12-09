//
//  ChartLegendTokenCell.swift
//  EarnModule
//
//  Created by Com1 on 07/12/2022.
//

import UIKit
import Services
import DesignSystem
import Utilities
import BigInt

class ChartLegendTokenCell: UICollectionViewCell {
    static let legendSize: CGSize = CGSize(width: 180, height: 44)
    
    @IBOutlet weak var legendColorView: UIView!
    @IBOutlet weak var tokenImageView: UIImageView!
    @IBOutlet weak var chainImageView: UIImageView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var balanceLabelLeading: NSLayoutConstraint!
    @IBOutlet weak var containtView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateUI(earningBalance: EarningBalance, totalValue: Double, index: Int) {
        balanceLabelLeading.constant = 65
        tokenImageView.isHidden = false
        chainImageView.isHidden = false
        legendColorView.backgroundColor = AppTheme.current.primaryColor
        tokenImageView.loadImage(earningBalance.toUnderlyingToken.logo)
        chainImageView.image = ChainType.make(chainID: earningBalance.chainID)?.chainIcon()
        
        var toUnderlyingBalanceString = "---"
        var detailString = "---"
        if let toUnderlyingBalanceBigInt = BigInt(earningBalance.toUnderlyingToken.balance) {
            if toUnderlyingBalanceBigInt < BigInt(pow(10.0, Double(earningBalance.toUnderlyingToken.decimals - 6))) {
                toUnderlyingBalanceString = "< 0.000001 \(earningBalance.toUnderlyingToken.symbol)"
            } else {
                toUnderlyingBalanceString = toUnderlyingBalanceBigInt.shortString(decimals: earningBalance.toUnderlyingToken.decimals) + " " + earningBalance.toUnderlyingToken.symbol
            }
            let usdBigIntValue = BigInt(earningBalance.underlyingUsd * pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals))) * toUnderlyingBalanceBigInt / BigInt(pow(10.0 , Double(earningBalance.toUnderlyingToken.decimals)))
            let usdDouble = usdBigIntValue.doubleValue(decimal: earningBalance.toUnderlyingToken.decimals)
            detailString = "$" + usdBigIntValue.shortString(decimals: earningBalance.toUnderlyingToken.decimals, maxFractionDigits: 2) + " | " + StringFormatter.percentString(value: usdDouble / totalValue)
        }
        balanceLabel.text = toUnderlyingBalanceString
        detailLabel.text = detailString
    }
    
    func updateUILastCell(totalValue: Double, remainValue: Double?) {
        balanceLabelLeading.constant = 28
        tokenImageView.isHidden = true
        chainImageView.isHidden = true
        legendColorView.backgroundColor = AppTheme.current.primaryColor
        balanceLabel.text = Strings.other
        if let remainValue = remainValue {
            detailLabel.text = StringFormatter.usdString(value: remainValue) + " | " +  StringFormatter.percentString(value: remainValue / totalValue)
        } else {
            detailLabel.text = ""
        }        
    }
    
}
