//
//  TxFooterCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import UIKit
import Utilities

class TxFooterCell: UITableViewCell {
    @IBOutlet weak var gasAmountLabel: UILabel!
    @IBOutlet weak var gasValueLabel: UILabel!
    @IBOutlet weak var hashLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.containerView.roundWithCustomCorner(corners: [.bottomLeft, .bottomRight], radius: 12)
        }
    }
    
    func configure(viewModel: TxHistoryFooterCellViewModel) {
        gasAmountLabel.text = viewModel.gasAmount
        gasValueLabel.text = viewModel.gasUsdValue
        hashLabel.text = viewModel.hash
    }
    
    @IBAction func openLinkTapped(_ sender: Any) {
        
    }
}
