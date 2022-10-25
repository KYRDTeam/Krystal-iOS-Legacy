//
//  ApprovedTokenCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import UIKit

class ApprovedTokenCell: UITableViewCell {
    @IBOutlet weak var tokenImageView: UIImageView!
    @IBOutlet weak var chainImageView: UIImageView!
    @IBOutlet weak var tokenSymbolLabel: UILabel!
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var verifyIcon: UIImageView!
    @IBOutlet weak var spenderAddressLabel: UILabel!
    @IBOutlet weak var rightTokenSymbolLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func configure(viewModel: ApprovedTokenItemViewModel) {
        tokenImageView.loadImage(viewModel.tokenIcon)
        chainImageView.image = viewModel.chainIcon
        tokenSymbolLabel.text = viewModel.symbol
        tokenNameLabel.text = viewModel.tokenName
        verifyIcon.isHidden = !viewModel.isVerified
        spenderAddressLabel.text = viewModel.spenderAddress.shortTypeAddress
        rightTokenSymbolLabel.text = viewModel.symbol
        amountLabel.text = viewModel.amount
    }
    
}
