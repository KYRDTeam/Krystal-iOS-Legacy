//
//  TxHeaderCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 21/12/2022.
//

import UIKit
import Utilities

class TxHeaderCell: UITableViewCell {
    @IBOutlet weak var typeIconImageView: UIImageView!
    @IBOutlet weak var typeNameLabel: UILabel!
    @IBOutlet weak var contractLabel: UILabel!
    @IBOutlet weak var chainIconImageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.containerView.roundWithCustomCorner(corners: [.topLeft, .topRight], radius: 12)
        }
        
    }
    
    func configure(viewModel: TxHistoryHeaderCellViewModel) {
        typeIconImageView.image = viewModel.typeIcon
        typeNameLabel.text = viewModel.typeString
        contractLabel.text = viewModel.contract
        chainIconImageView.loadImage(viewModel.chainIcon)
    }
    
}
