//
//  ApprovedTokenCell.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import UIKit
import SwipeCellKit

class ApprovedTokenCell: SwipeTableViewCell {
    @IBOutlet weak var tokenImageView: UIImageView!
    @IBOutlet weak var chainImageView: UIImageView!
    @IBOutlet weak var tokenSymbolLabel: UILabel!
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var verifyIcon: UIImageView!
    @IBOutlet weak var spenderAddressLabel: UILabel!
    @IBOutlet weak var rightTokenSymbolLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    var onTapTokenSymbol: (() -> ())?
    var onTapSpenderAddress: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        rightTokenSymbolLabel.isUserInteractionEnabled = true
        rightTokenSymbolLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTokenSymbol)))
        
        spenderAddressLabel.isUserInteractionEnabled = true
        spenderAddressLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSpenderAddress)))
    }
    
    @objc func tapTokenSymbol() {
        onTapTokenSymbol?()
    }
    
    @objc func tapSpenderAddress() {
        onTapSpenderAddress?()
    }
    
    func configure(viewModel: ApprovedTokenItemViewModel) {
        tokenImageView.setImage(with: viewModel.tokenIcon ?? "", placeholder: UIImage(named: "default_token")!)
        chainImageView.image = viewModel.chainIcon
        tokenSymbolLabel.text = viewModel.symbol
        tokenNameLabel.text = viewModel.tokenName
        verifyIcon.isHidden = !viewModel.isVerified
        spenderAddressLabel.text = viewModel.spenderValue
        rightTokenSymbolLabel.text = viewModel.symbol
        amountLabel.text = viewModel.amountString
        chainImageView.isHidden = !viewModel.showChainIcon
    }
    
}
