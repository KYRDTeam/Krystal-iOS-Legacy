//
//  EarningTypeCell.swift
//  EarnModule
//
//  Created by Com1 on 12/12/2022.
//

import UIKit
import Services
import DesignSystem

class EarningTypeCell: UITableViewCell {
    @IBOutlet weak var stakeButton: UIButton!
    @IBOutlet weak var lendButton: UIButton!
    var selectedType: [EarningType]!
    var onSelectedType: (([EarningType]) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateUI() {
        if selectedType.contains(.staking) {
            stakeButton.backgroundColor = AppTheme.current.primaryColor.withAlphaComponent(0.2)
        } else {
            stakeButton.backgroundColor = AppTheme.current.sectionBackgroundColor
        }
        
        if selectedType.contains(.lending) {
            lendButton.backgroundColor = AppTheme.current.primaryColor.withAlphaComponent(0.2)
        } else {
            lendButton.backgroundColor = AppTheme.current.sectionBackgroundColor
        }
    }
    
    @IBAction func onStakeButtonTapped(_ sender: Any) {
        if selectedType.contains(.staking) {
            selectedType = selectedType.filter({$0 != .staking})
            stakeButton.backgroundColor = AppTheme.current.sectionBackgroundColor
        } else {
            selectedType.append(.staking)
            stakeButton.backgroundColor = AppTheme.current.primaryColor.withAlphaComponent(0.2)
        }
        onSelectedType?(selectedType)
    }

    @IBAction func onLendButtonTapped(_ sender: Any) {
        if selectedType.contains(.lending) {
            selectedType = selectedType.filter({$0 != .lending})
            lendButton.backgroundColor = AppTheme.current.sectionBackgroundColor
        } else {
            selectedType.append(.lending)
            lendButton.backgroundColor = AppTheme.current.primaryColor.withAlphaComponent(0.2)
        }
        onSelectedType?(selectedType)
    }
}
