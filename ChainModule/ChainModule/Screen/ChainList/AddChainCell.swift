//
//  AddChainCell.swift
//  ChainModule
//
//  Created by Tung Nguyen on 20/02/2023.
//

import UIKit

class AddChainCell: UITableViewCell {
    
    var addNetworkWasTapped: (() -> ())?

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    @IBAction func addTapped(_ sender: Any) {
        addNetworkWasTapped?()
    }
}
