//
//  TxDateCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import UIKit
import Utilities

class TxDateCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    
    func configure(date: Date) {
        dateLabel.text = DateFormatterUtil.shared.MMMMddYYYY.string(from: date)
    }
}
