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

    func updateUI(earningBalance: EarningBalance, totalValue: Double, shouldShowChainIcon: Bool, index: Int) {
        balanceLabelLeading.constant = 65
        tokenImageView.isHidden = false
        chainImageView.isHidden = !shouldShowChainIcon
        legendColorView.backgroundColor = AppTheme.current.chartColors[index]
        tokenImageView.loadImage(earningBalance.toUnderlyingToken.logo)
        chainImageView.image = ChainType.make(chainID: earningBalance.chainID)?.chainIcon()
        balanceLabel.text = earningBalance.balanceString(totalValue: totalValue)
        detailLabel.text = earningBalance.usdDetailString()
    }
    
    func updateUILastCell(totalValue: Double, remainValue: Double?) {
        balanceLabelLeading.constant = 28
        tokenImageView.isHidden = true
        chainImageView.isHidden = true
        legendColorView.backgroundColor = AppTheme.current.chartColors.last
        if let remainValue = remainValue {
            balanceLabel.text = Strings.other + " " +  StringFormatter.percentString(value: remainValue / totalValue)
            detailLabel.text = StringFormatter.usdString(value: remainValue)
        } else {
            balanceLabel.text = Strings.other
            detailLabel.text = ""
        }
    }
    
}
