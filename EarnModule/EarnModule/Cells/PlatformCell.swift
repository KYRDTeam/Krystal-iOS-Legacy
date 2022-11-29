//
//  PlatformCell.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 22/11/2022.
//

import UIKit
import Services

class PlatformCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectedIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateCell(platform: EarnPlatform?, isSelected: Bool) {
        guard let platform = platform else {
            iconImageView.image = Images.allNetworkIcon
            nameLabel.text = Strings.allPlatforms
            selectedIcon.isHidden = !isSelected
            return
        }
        iconImageView.setImage(urlString: platform.logo, symbol: "")
        nameLabel.text = platform.name.capitalized
        selectedIcon.isHidden = !isSelected
    }
}
