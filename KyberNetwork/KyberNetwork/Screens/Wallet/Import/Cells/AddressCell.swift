//
//  AddressCell.swift
//  KyberNetwork
//
//  Created by Com1 on 01/03/2023.
//

import UIKit
import KrystalWallets

class AddressCell: UITableViewCell {
    static let height = CGFloat(136)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mainChainIcon: UIImageView!
    @IBOutlet var otherChainsView: [UIView]!
    @IBOutlet weak var dashView: UIView!
    var onCopyButtonTapped: ((String) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configUI(walletType: KAddressType, address: String) {
        if walletType == .solana {
            otherChainsView.forEach { view in
                view.isHidden = true
            }
            titleLabel.text = "Solana address"
            mainChainIcon.image = Images.chainSolana
        }
        addressLabel.text = address
    }
    
    @IBAction func copyButtonTapped(_ sender: Any) {
        if let text = addressLabel.text {
            onCopyButtonTapped?(text)
        }
        
    }
}
