//
//  TransactionSettingBasicTab.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import UIKit
import DesignSystem
import BaseWallet
import AppState

class TransactionSettingBasicTab: BaseTransactionSettingTab {
    @IBOutlet weak var superFastRadioButton: RadioButton!
    @IBOutlet weak var fastRadioButton: RadioButton!
    @IBOutlet weak var regularRadioButton: RadioButton!
    @IBOutlet weak var slowRadioButton: RadioButton!
    @IBOutlet weak var totalGasView: UIView!
    @IBOutlet weak var estimatedGasTitleLabel: UILabel!
    @IBOutlet weak var estimatedGasAmountLabel: UILabel!
    @IBOutlet weak var estimatedGasUsdValueLabel: UILabel!
    
    @IBOutlet weak var superFastGasFee: UILabel!
    @IBOutlet weak var fastGasFee: UILabel!
    @IBOutlet weak var regularGasFee: UILabel!
    @IBOutlet weak var slowGasFee: UILabel!
    
    @IBOutlet weak var superFastGasAmount: UILabel!
    @IBOutlet weak var fastGasAmount: UILabel!
    @IBOutlet weak var regularGasAmount: UILabel!
    @IBOutlet weak var slowGasAmount: UILabel!
    
    var viewModel: TransactionSettingBasicTabViewModel!
    var onUpdateSettings: ((TxSettingObject) -> ())?
    
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
        superFastGasFee.attributedText = viewModel.getGasOptionText(gasType: .superFast)
        fastGasFee.attributedText = viewModel.getGasOptionText(gasType: .fast)
        regularGasFee.attributedText = viewModel.getGasOptionText(gasType: .regular)
        slowGasFee.attributedText = viewModel.getGasOptionText(gasType: .slow)
        
        superFastGasAmount.text = viewModel.getEstimatedGasFee(gasType: .superFast)
        fastGasAmount.text = viewModel.getEstimatedGasFee(gasType: .fast)
        regularGasAmount.text = viewModel.getEstimatedGasFee(gasType: .regular)
        slowGasAmount.text = viewModel.getEstimatedGasFee(gasType: .slow)
    }
    
    func uncheckAll() {
        superFastRadioButton.isChecked = false
        fastRadioButton.isChecked = false
        regularRadioButton.isChecked = false
        slowRadioButton.isChecked = false
    }
    
    @IBAction func superFastTapped(_ sender: Any) {
        uncheckAll()
        superFastRadioButton.isChecked = true
        selectGasType(gasType: .superFast)
    }
    
    @IBAction func fastTapped(_ sender: Any) {
        uncheckAll()
        fastRadioButton.isChecked = true
        selectGasType(gasType: .fast)
    }
    
    @IBAction func regularTapped(_ sender: Any) {
        uncheckAll()
        regularRadioButton.isChecked = true
        selectGasType(gasType: .regular)
    }
    
    @IBAction func slowTapped(_ sender: Any) {
        uncheckAll()
        slowRadioButton.isChecked = true
        selectGasType(gasType: .slow)
    }
    
    @IBAction func superFastContentTapped(_ sender: Any) {
        uncheckAll()
        superFastRadioButton.isChecked = true
        selectGasType(gasType: .superFast)
    }
    
    @IBAction func fastContentTapped(_ sender: Any) {
        uncheckAll()
        fastRadioButton.isChecked = true
        selectGasType(gasType: .fast)
    }
    
    @IBAction func regularContentTapped(_ sender: Any) {
        uncheckAll()
        regularRadioButton.isChecked = true
        selectGasType(gasType: .regular)
    }
    
    @IBAction func slowContentTapped(_ sender: Any) {
        uncheckAll()
        slowRadioButton.isChecked = true
        selectGasType(gasType: .slow)
    }
    
    func selectGasType(gasType: GasType) {
        viewModel.selectGasType(gasType: gasType)
        onUpdateSettings?(viewModel.settingObject)
        estimatedGasAmountLabel.text = viewModel.getEstimatedGasFee(setting: viewModel.settingObject)
        estimatedGasUsdValueLabel.text = viewModel.getMaxFeeString(setting: viewModel.settingObject)
    }
    
    func updateSettings(settings: TxSettingObject) {
        viewModel.settingObject = settings
        estimatedGasAmountLabel.text = viewModel.getEstimatedGasFee(setting: settings)
        estimatedGasUsdValueLabel.text = viewModel.getMaxFeeString(setting: settings)
    }
    
}
