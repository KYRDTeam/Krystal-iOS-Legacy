//
//  TokenSelectCell.swift
//  TokenModule
//
//  Created by Tung Nguyen on 23/12/2022.
//

import UIKit
import Services
import BaseWallet
import Utilities

class TokenSelectCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var chainImageView: UIImageView!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var verifyImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(token: AdvancedSearchToken) {
        if token.logo.isEmpty {
            iconImageView.image = Images.defaultToken
        } else {
            iconImageView.loadImage(token.logo)
        }
        symbolLabel.text = token.symbol
        nameLabel.text = token.name
        chainImageView.image = ChainType.make(chainID: token.chainId)?.squareIcon()
        verifyImageView.image = TokenVerifyStatus(value: token.tag).icon
    }
}
