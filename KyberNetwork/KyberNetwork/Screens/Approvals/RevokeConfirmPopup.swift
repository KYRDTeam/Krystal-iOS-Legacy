//
//  RevokeConfirmPopup.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 26/10/2022.
//

import UIKit
import Services

class RevokeConfirmPopup: UIViewController {
    @IBOutlet weak var tokenIconImageView: UIImageView!
    @IBOutlet weak var chainIconImageView: UIImageView!
    @IBOutlet weak var tokenSymbolLabel: UILabel!
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var allowanceLabel: UILabel!
    @IBOutlet weak var contractLabel: UILabel!
    @IBOutlet weak var spenderAddressLabel: UILabel!
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var feeFomularLabel: UILabel!
    @IBOutlet weak var verifyIcon: UIImageView!
    
    var viewModel: RevokeConfirmViewModel!
    var onSelectRevoke: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    func setupViews() {
        contractLabel.text = viewModel.contract
        tokenIconImageView.setImage(with: viewModel.tokenIcon ?? "", placeholder: UIImage(named: "default_token")!)
        chainIconImageView.image = viewModel.chainIcon
        tokenSymbolLabel.text = viewModel.symbol
        tokenNameLabel.text = viewModel.tokenName
        verifyIcon.isHidden = !viewModel.isVerified
        spenderAddressLabel.text = viewModel.spenderAddress
        allowanceLabel.text = viewModel.amountString
    }

    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func revokeTapped(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            self?.onSelectRevoke?()
        }
    }
    
}
