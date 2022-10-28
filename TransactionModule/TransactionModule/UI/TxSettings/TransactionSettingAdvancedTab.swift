//
//  TransactionSettingAdvancedTab.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import UIKit
import BaseWallet
import AppState

class TransactionSettingAdvancedTab: UIViewController {
    @IBOutlet weak var totalGasView: UIView!
    
    var currentChain: ChainType {
        return AppState.shared.currentChain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    func setupViews() {
        if !currentChain.isSupportedEIP1559() {
            totalGasView.removeFromSuperview()
        }
    }

}
