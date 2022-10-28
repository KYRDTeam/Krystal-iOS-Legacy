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
    @IBOutlet weak var estimatedGasLabel: UILabel!
    @IBOutlet weak var estimatedGasUsdValueLabel: UILabel!
    
    var viewModel: TransactionSettingAdvancedTabViewModel!
    var onUpdateSettings: ((TxSettingObject) -> ())?
    
    var currentChain: ChainType {
        return AppState.shared.currentChain
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        updateValues()
    }
    
    func setupViews() {
        if !currentChain.isSupportedEIP1559() {
            totalGasView.removeFromSuperview()
        }
    }
    
    func updateSettings(settings: TxSettingObject) {
        viewModel.settingObject = settings
        updateValues()
    }
    
    func updateValues() {
        estimatedGasLabel?.text = viewModel.getEstimatedGasFee(setting: viewModel.settingObject)
        estimatedGasUsdValueLabel?.text = viewModel.getMaxFeeString(setting: viewModel.settingObject)
    }

}
