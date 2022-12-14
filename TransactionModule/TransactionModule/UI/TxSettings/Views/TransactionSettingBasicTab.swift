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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        reloadEstimatedGasUI()
    }
    
    func setupViews() {
        if !viewModel.chain.isSupportedEIP1559() {
            totalGasView.removeFromSuperview()
        }
        
        resetUI()
        if viewModel.setting.advanced != nil {
            self.uncheckAll()
        }
    }
    
    func resetUI() {
        superFastGasFee.attributedText = viewModel.getGasOptionText(gasType: .superFast)
        fastGasFee.attributedText = viewModel.getGasOptionText(gasType: .fast)
        regularGasFee.attributedText = viewModel.getGasOptionText(gasType: .regular)
        slowGasFee.attributedText = viewModel.getGasOptionText(gasType: .slow)
        
        superFastGasAmount.text = viewModel.getEstimatedGasFee(gasType: .superFast)
        fastGasAmount.text = viewModel.getEstimatedGasFee(gasType: .fast)
        regularGasAmount.text = viewModel.getEstimatedGasFee(gasType: .regular)
        slowGasAmount.text = viewModel.getEstimatedGasFee(gasType: .slow)
    }
    
    func onGasPriceUpdated() {
        resetUI()
        reloadEstimatedGasUI()
    }
    
    func uncheckAll() {
        superFastRadioButton.isChecked = false
        fastRadioButton.isChecked = false
        regularRadioButton.isChecked = false
        slowRadioButton.isChecked = false
    }
    
    @IBAction func gasFeeAboutTapped(_ sender: Any) {
        showBottomBannerView(message: Strings.gasFeeAbout,
                             icon: Images.helpIcon,
                             time: 10)
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
    
    func selectGasType(gasType: GasSpeed) {
        viewModel.selectGasType(gasType: gasType)
        onUpdateSettings?(viewModel.setting)
        resetUI()
        reloadEstimatedGasUI()
    }
    
    func updateSettings(settings: TxSettingObject) {
        viewModel.setting = settings
        resetUI()
        reloadEstimatedGasUI()
        if viewModel.setting.advanced != nil {
            self.uncheckAll()
        }
    }
    
    func reloadEstimatedGasUI() {
        if let basic = viewModel.setting.basic {
            viewModel.selectGasType(gasType: basic.gasType)
            uncheckAll()
            switch basic.gasType {
            case .superFast:
                superFastRadioButton.isChecked = true
            case .fast:
                fastRadioButton.isChecked = true
            case .regular:
                regularRadioButton.isChecked = true
            case .slow:
                slowRadioButton.isChecked = true
            }
        }
        estimatedGasAmountLabel?.text = viewModel.getEstimatedGasFee()
        estimatedGasUsdValueLabel?.text = viewModel.getMaxFeeString()
    }
    
}
