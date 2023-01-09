//
//  HistoryStatsCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 05/01/2023.
//

import UIKit

class HistoryStatsCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    func configure(type: TxStatsCellType) {
        iconImageView.image = type.icon
        titleLabel.text = type.title
        valueLabel.text = type.valueString
    }
}
