//
//  TransactionSettingAdvancedTab.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import UIKit
import BaseWallet
import AppState
import BigInt
import DesignSystem

class TransactionSettingAdvancedTab: UIViewController {
    @IBOutlet weak var totalGasView: UIView!
    @IBOutlet weak var estimatedGasLabel: UILabel!
    @IBOutlet weak var estimatedGasUsdValueLabel: UILabel!
    @IBOutlet weak var gasLimitErrorLabel: UILabel!
    @IBOutlet weak var maxPriorityFeeErrorLabel: UILabel!
    @IBOutlet weak var maxFeeErrorLabel: UILabel!
    @IBOutlet weak var currentNonceErrorLabel: UILabel!
    @IBOutlet weak var gasLimitField: UITextField!
    @IBOutlet weak var priorityField: UITextField!
    @IBOutlet weak var maxFeeField: UITextField!
    @IBOutlet weak var nonceField: UITextField!
    @IBOutlet weak var equivalentPriorityETHFeeLabel: UILabel!
    @IBOutlet weak var equivalentMaxETHFeeLabel: UILabel!
    @IBOutlet weak var maxFeeAccessoryLabel: UILabel!
    @IBOutlet weak var priorityAccessoryLabel: UILabel!
    
    @IBOutlet weak var maxPriorityFeeTitleLabel: UILabel!
    @IBOutlet weak var maxPriorityView: UIView!
    @IBOutlet weak var maxPriorityInfoButton: UIButton!
    @IBOutlet weak var maxFeeTitleLabel: UILabel!
    
    var viewModel: TransactionSettingAdvancedTabViewModel!
    var onUpdateSettings: ((TxSettingObject) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        reloadEstimatedGasUI()
        reloadSettingUI()
        loadLatestNonce()
    }
    
    func loadLatestNonce() {
        viewModel.getLatestNonce { [weak self] nonce in
            self?.nonceField.text = nonce.map(String.init)
        }
    }
    
    func setupViews() {
        if !viewModel.chain.isSupportedEIP1559() {
            totalGasView.removeFromSuperview()
            maxPriorityFeeTitleLabel.removeFromSuperview()
            maxPriorityView.removeFromSuperview()
            maxPriorityInfoButton.removeFromSuperview()
            maxPriorityFeeErrorLabel.removeFromSuperview()
        }
        
        maxFeeTitleLabel.text = viewModel.chain.isSupportedEIP1559() ? Strings.maxFee : Strings.gasPrice
        
        gasLimitField.delegate = self
        priorityField.delegate = self
        maxFeeField.delegate = self
        nonceField.delegate = self
        
        gasLimitField.text = viewModel.gasLimitText
        priorityField.text = viewModel.priorityText
        maxFeeField.text = viewModel.maxFeeText
        nonceField.text = viewModel.nonceText
    }
    
    func updateSettings(settings: TxSettingObject) {
        viewModel.setting = settings
        resetUI()
        reloadEstimatedGasUI()
        reloadSettingUI()
    }
    
    func resetUI() {
        gasLimitField?.text = viewModel.gasLimitText
        priorityField?.text = viewModel.priorityText
        maxFeeField?.text = viewModel.maxFeeText
        nonceField?.text = viewModel.nonceText
    }
    
    func reloadEstimatedGasUI() {
        estimatedGasLabel?.text = viewModel.getEstimatedGasFee()
        estimatedGasUsdValueLabel?.text = viewModel.getMaxFeeString()
    }
    
    func updateGasLimit(value: BigInt) {
        viewModel.updateGasLimit(value: value)
        onUpdateSettings?(viewModel.setting)
        reloadGasLimitUI()
        reloadEstimatedGasUI()
    }
    
    func updateMaxPriorityFee(value: BigInt) {
        viewModel.updateMaxPriorityFee(value: value)
        onUpdateSettings?(viewModel.setting)
        reloadPriorityUI()
        reloadEstimatedGasUI()
    }
    
    func updateMaxFee(value: BigInt) {
        viewModel.updateMaxFee(value: value)
        onUpdateSettings?(viewModel.setting)
        reloadMaxFeeUI()
        reloadEstimatedGasUI()
    }
    
    func updateNonce(value: Int) {
        viewModel.updateNonce(value: value)
        onUpdateSettings?(viewModel.setting)
        reloadNonceUI()
    }
    
    func onGasPriceUpdated() {
        resetUI()
        reloadEstimatedGasUI()
    }
    
    func reloadSettingUI() {
        reloadGasLimitUI()
        reloadPriorityUI()
        reloadMaxFeeUI()
        reloadNonceUI()
    }
    
    func reloadGasLimitUI() {
        if let gasLimitError = viewModel.gasLimitError, gasLimitError == .low {
            gasLimitField?.textColor = AppTheme.current.errorTextColor
            gasLimitErrorLabel?.text = "Gas limit must be at least \(TransactionConstants.lowestGasLimit)"
        } else {
            gasLimitField?.textColor = AppTheme.current.primaryTextColor
            gasLimitErrorLabel?.text = nil
        }
    }

    func reloadPriorityUI() {
        if let priorityError = viewModel.priorityError {
            switch priorityError {
            case .high:
                priorityField?.textColor = AppTheme.current.errorTextColor
                maxPriorityFeeErrorLabel?.text = "Max Priority Fee is higher than necessary"
                equivalentPriorityETHFeeLabel?.textColor = AppTheme.current.errorTextColor.withAlphaComponent(0.5)
                priorityAccessoryLabel?.textColor = AppTheme.current.errorTextColor
            case .low:
                priorityField?.textColor = AppTheme.current.errorTextColor
                maxPriorityFeeErrorLabel?.text = "Max Priority Fee is low for current network conditions"
                equivalentPriorityETHFeeLabel?.textColor = AppTheme.current.errorTextColor.withAlphaComponent(0.5)
                priorityAccessoryLabel?.textColor = AppTheme.current.errorTextColor
            case .empty:
                priorityField?.textColor = AppTheme.current.primaryTextColor
                maxPriorityFeeErrorLabel?.text = nil
                equivalentPriorityETHFeeLabel?.textColor = AppTheme.current.secondaryTextColor
                priorityAccessoryLabel?.textColor = AppTheme.current.primaryTextColor
            }
        } else {
            priorityField?.textColor = AppTheme.current.primaryTextColor
            maxPriorityFeeErrorLabel?.text = nil
            equivalentPriorityETHFeeLabel?.textColor = AppTheme.current.secondaryTextColor
            priorityAccessoryLabel?.textColor = AppTheme.current.primaryTextColor
        }
        equivalentPriorityETHFeeLabel?.text = viewModel.displayEquivalentPriorityETHFee
    }
    
    func reloadMaxFeeUI() {
        if let maxFeeError = viewModel.maxFeeError {
            switch maxFeeError {
            case .high:
                maxFeeErrorLabel?.text = "Max Fee is higher than necessary"
                maxFeeField?.textColor = AppTheme.current.errorTextColor
                maxFeeAccessoryLabel?.textColor = AppTheme.current.errorTextColor
                equivalentMaxETHFeeLabel?.textColor = AppTheme.current.errorTextColor.withAlphaComponent(0.5)
            case .low:
                maxFeeErrorLabel?.text = "Max Fee is low for current network conditions"
                maxFeeField?.textColor = AppTheme.current.errorTextColor
                maxFeeAccessoryLabel?.textColor = AppTheme.current.errorTextColor
                equivalentMaxETHFeeLabel?.textColor = AppTheme.current.errorTextColor.withAlphaComponent(0.5)
            case .empty:
                maxFeeErrorLabel?.text = nil
                maxFeeField?.textColor = AppTheme.current.primaryTextColor
                maxFeeAccessoryLabel?.textColor = AppTheme.current.primaryTextColor
                equivalentMaxETHFeeLabel?.textColor = AppTheme.current.secondaryTextColor
            }
        } else {
            maxFeeErrorLabel?.text = nil
            maxFeeField?.textColor = AppTheme.current.primaryTextColor
            maxFeeAccessoryLabel?.textColor = AppTheme.current.primaryTextColor
            equivalentMaxETHFeeLabel?.textColor = AppTheme.current.secondaryTextColor
        }
        equivalentMaxETHFeeLabel?.text = viewModel.displayEquivalentMaxETHFee
    }
    
    func reloadNonceUI() {
        if let nonceError = viewModel.nonceError {
            switch nonceError {
            case .low:
                nonceField?.textColor = AppTheme.current.errorTextColor
                currentNonceErrorLabel?.text = "Nonce is too low"
            case .high:
                nonceField?.textColor = AppTheme.current.errorTextColor
                currentNonceErrorLabel?.text = "Nonce is too high"
            default:
                nonceField?.textColor = AppTheme.current.primaryTextColor
                currentNonceErrorLabel?.text = nil
            }
        } else {
            nonceField?.textColor = AppTheme.current.primaryTextColor
            currentNonceErrorLabel?.text = nil
        }
    }
    
    func showHelp(message: String) {
        showBottomBannerView(message: message,
                             icon: Images.helpIcon,
                             time: 10)
    }
    
    @IBAction func gasLimitInfoTapped(_ sender: Any) {
        showHelp(message: viewModel.chain.isSupportedEIP1559() ? Strings.gasLimitAbout : Strings.gasLimitLegacyAbout)
    }
    
    @IBAction func maxPriorityFeeInfoTapped(_ sender: Any) {
        showHelp(message: Strings.maxPriorityAbout)
    }
    
    @IBAction func maxFeeInfoTapped(_ sender: Any) {
        showHelp(message: viewModel.chain.isSupportedEIP1559() ? Strings.maxFeeAbout : Strings.gasPriceAbout)
    }
    
    @IBAction func customNonceInfoTapped(_ sender: Any) {
        showHelp(message: Strings.nonceAbout)
    }
    
    @IBAction func gasLimitDecreaseTapped(_ sender: Any) {
        let newGasLimit = viewModel.gasLimit - BigInt(1000)
        if newGasLimit > 0 {
            updateGasLimit(value: newGasLimit)
            gasLimitField.text = viewModel.gasLimitText
        }
    }
    
    @IBAction func gasLimitIncreaseTapped(_ sender: Any) {
        updateGasLimit(value: viewModel.gasLimit + BigInt(1000))
        gasLimitField.text = viewModel.gasLimitText
    }
    
    @IBAction func priorityDecreaseTapped(_ sender: Any) {
        let newPriorityFee = viewModel.priorityFee - BigInt(1_000_000_000) / BigInt(2)
        if newPriorityFee > 0 {
            updateMaxPriorityFee(value: newPriorityFee)
            priorityField.text = viewModel.priorityText
        }
    }
    
    @IBAction func priorityIncreaseTapped(_ sender: Any) {
        updateMaxPriorityFee(value: viewModel.priorityFee + BigInt(1_000_000_000) / BigInt(2))
        priorityField.text = viewModel.priorityText
    }
    
    @IBAction func maxFeeDecreaseTapped(_ sender: Any) {
        let newMaxFee = viewModel.maxFee - BigInt(1_000_000_000) / BigInt(2)
        if newMaxFee > 0 {
            updateMaxFee(value: newMaxFee)
            maxFeeField.text = viewModel.maxFeeText
        }
    }
    
    @IBAction func maxFeeIncreaseTapped(_ sender: Any) {
        updateMaxFee(value: viewModel.maxFee + BigInt(1_000_000_000) / BigInt(2))
        maxFeeField.text = viewModel.maxFeeText
    }
    
    @IBAction func nonceDecreaseTapped(_ sender: Any) {
        let newNonce = viewModel.nonce - 1
        if newNonce > 0 {
            updateNonce(value: newNonce)
            nonceField.text = viewModel.nonceText
        }
    }
    
    @IBAction func nonceIncreaseTapped(_ sender: Any) {
        updateNonce(value: viewModel.nonce + 1)
        nonceField.text = viewModel.nonceText
    }

}

extension TransactionSettingAdvancedTab: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case gasLimitField:
            gasLimitField.text = viewModel.gasLimitText
        case priorityField:
            priorityField.text = viewModel.priorityText
        case maxFeeField:
            maxFeeField.text = viewModel.maxFeeText
        case nonceField:
            nonceField.text = viewModel.nonceText
        default:
            return true
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        let doubleValue = text.toDouble() ?? 0
        switch textField {
        case gasLimitField:
            let bigIntValue = BigInt(doubleValue)
            self.updateGasLimit(value: bigIntValue)
            return true
        case priorityField:
            let bigIntValue = BigInt(doubleValue * pow(10, 9))
            self.updateMaxPriorityFee(value: bigIntValue)
            return true
        case maxFeeField:
            let bigIntValue = BigInt(doubleValue * pow(10, 9))
            self.updateMaxFee(value: bigIntValue)
            return true
        case nonceField:
            self.updateNonce(value: Int(doubleValue))
            return true
        default:
            return true
        }
    }
    
}
