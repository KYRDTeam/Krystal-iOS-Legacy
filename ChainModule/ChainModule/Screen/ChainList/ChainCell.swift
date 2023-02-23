//
//  ChainCell.swift
//  ChainModule
//
//  Created by Tung Nguyen on 15/02/2023.
//

import UIKit
import Utilities
import DesignSystem

class ChainCell: UITableViewCell {
    @IBOutlet weak var iconImageVieW: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectingBackgroundView: UIView!
    @IBOutlet weak var checkmarkIcon: UIImageView!
    
    func configure(chain: Chain, isSelected: Bool) {
        iconImageVieW.loadImage(chain.iconUrl)
        nameLabel.text = chain.name
        selectingBackgroundView.backgroundColor = isSelected ? AppTheme.current.primaryColor.withAlphaComponent(0.2) : .clear
        checkmarkIcon.isHidden = !isSelected
    }
    
}
