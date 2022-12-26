//
//  TxNFTCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 26/12/2022.
//

import UIKit
import DesignSystem

class TxNFTCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(viewModel: TxNFTCellViewModel) {
        if viewModel.imageUrl.isNilOrEmpty {
            iconImageView.image = .txNFT
        } else {
            iconImageView.loadImage(viewModel.imageUrl, placeholder: .txNFT)
        }
        nameLabel.text = viewModel.amountString
        nameLabel.textColor = viewModel.isPositiveAmount ? AppTheme.current.primaryColor : AppTheme.current.primaryTextColor
    }
    
}
