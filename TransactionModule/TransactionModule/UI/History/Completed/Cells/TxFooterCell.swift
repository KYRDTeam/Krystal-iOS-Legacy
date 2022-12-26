//
//  TxFooterCell.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import UIKit
import Utilities
import BaseWallet

class TxFooterCell: UITableViewCell {
    @IBOutlet weak var gasAmountLabel: UILabel!
    @IBOutlet weak var gasValueLabel: UILabel!
    @IBOutlet weak var hashLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    var viewModel: TxHistoryFooterCellViewModel?
    var onSelectOpenExplore: ((Int, String) -> ())?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.containerView.roundWithCustomCorner(corners: [.bottomLeft, .bottomRight], radius: 12)
        }
    }
    
    func configure(viewModel: TxHistoryFooterCellViewModel) {
        self.viewModel = viewModel
        gasAmountLabel.text = viewModel.gasAmount
        gasValueLabel.text = viewModel.gasUsdValue
        hashLabel.text = viewModel.shortenedTxHash
    }
    
    @IBAction func openLinkTapped(_ sender: Any) {
        guard let viewModel = viewModel else {
            return
        }
        onSelectOpenExplore?(viewModel.chainId, viewModel.txHash)
    }
}
