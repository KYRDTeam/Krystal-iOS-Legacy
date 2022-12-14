//
//  PortfolioHeaderView.swift
//  EarnModule
//
//  Created by Com1 on 06/12/2022.
//

import UIKit
import Utilities

class PortfolioHeaderView: BaseXibView {
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var arrowIcon: UIImageView!
    @IBOutlet weak var titleLable: UILabel!
    var isExpand: Bool = false {
        didSet {
            arrowIcon.image = isExpand ? Images.arrowUpIcon : Images.arrowDownIcon
        }
    }
    var onTapped: ((Bool) -> Void)?
    var shouldShowIcon: Bool = false {
        didSet {
            titleLeadingConstraint.constant = shouldShowIcon ? 52 : 24
            iconImageView.isHidden = !shouldShowIcon
        }
    }

    @IBAction func onViewButtonTapped(_ sender: Any) {
        isExpand = !isExpand
        onTapped?(isExpand)
    }
}
