//
//  ExploreMenuCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import UIKit

class ExploreMenuCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newTagImageView: UIImageView!
    
    func configure(item: ExploreMenuItemViewModel) {
        titleLabel.text = item.title
        iconImageView.image = item.icon
        newTagImageView.isHidden = !item.isNewFeature
    }
    
}
