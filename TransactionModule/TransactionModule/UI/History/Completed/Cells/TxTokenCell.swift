//
//  TxTokenCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 21/12/2022.
//

import UIKit
import Utilities
import DesignSystem

class TxTokenCell: UITableViewCell {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var verifyImageView: UIImageView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var usdValueLabel: UILabel!
    
    func configure(viewModel: TxHistoryTokenCellViewModel) {
        logoImageView.loadImage(viewModel.tokenIconUrl)
        verifyImageView.image = viewModel.verifyIcon
        amountLabel.text = viewModel.amount
        usdValueLabel.text = viewModel.usdValue
        amountLabel.textColor = viewModel.isTokenChangePositive ? AppTheme.current.primaryColor : AppTheme.current.primaryTextColor
    }
    
}
