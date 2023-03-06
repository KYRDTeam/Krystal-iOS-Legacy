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
    @IBOutlet weak var containView: UIView!
    
    
    var onCopyButtonTapped: ((String) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configUI(walletType: KAddressType, address: String, roundCornerAll: Bool = true) {
        if walletType == .solana {
            otherChainsView.forEach { view in
                view.isHidden = true
            }
            titleLabel.text = "Solana address"
            mainChainIcon.image = Images.chainSolana
        }
        addressLabel.text = address
        
        DispatchQueue.main.async {
            if roundCornerAll {
                self.containView.kn_radius = 16
            } else if walletType == .evm {
                self.containView.roundWithCustomCorner(corners: [.topRight, .topLeft], radius: 16)
            } else {
                self.containView.roundWithCustomCorner(corners: [.bottomRight, .bottomLeft], radius: 16)
            }
        }
    }

    @IBAction func copyButtonTapped(_ sender: Any) {
        if let text = addressLabel.text {
            onCopyButtonTapped?(text)
        }
        
    }
}
