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

class TransactionSettingBasicTab: UIViewController {
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
    }
    
    @IBAction func fastTapped(_ sender: Any) {
        uncheckAll()
        fastRadioButton.isChecked = true
    }
    
    @IBAction func regularTapped(_ sender: Any) {
        uncheckAll()
        regularRadioButton.isChecked = true
    }
    
    @IBAction func slowTapped(_ sender: Any) {
        uncheckAll()
        slowRadioButton.isChecked = true
    }
    
    @IBAction func superFastContentTapped(_ sender: Any) {
        uncheckAll()
        superFastRadioButton.isChecked = true
    }
    
    @IBAction func fastContentTapped(_ sender: Any) {
        uncheckAll()
        fastRadioButton.isChecked = true
    }
    
    @IBAction func regularContentTapped(_ sender: Any) {
        uncheckAll()
        regularRadioButton.isChecked = true
    }
    
    @IBAction func slowContentTapped(_ sender: Any) {
        uncheckAll()
        slowRadioButton.isChecked = true
    }
    
}
