//
//  UnstakeViewController.swift
//  EarnModule
//
//  Created by Com1 on 08/11/2022.
//

import UIKit
import DesignSystem
import AppState
import TransactionModule
import BigInt

enum UnstakeButtonState {
    case normal
    case disable
    case approve
}

class UnstakeViewController: InAppBrowsingViewController {
    @IBOutlet weak var unstakePlatformLabel: UILabel!
    @IBOutlet weak var availableUnstakeValue: UILabel!
    @IBOutlet weak var unstakeButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var tokenIcon: UIImageView!
    @IBOutlet weak var amountViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var amountView: UIView!
    
    @IBOutlet weak var receiveInfoView: TxInfoView!
    @IBOutlet weak var rateView: TxInfoView!
    @IBOutlet weak var networkFeeView: TxInfoView!
    @IBOutlet weak var receiveTimeView: TxInfoView!
    
    var viewModel: UnstakeViewModel?
    var unstakeButtonState: UnstakeButtonState = .disable {
        didSet {
            switch self.unstakeButtonState {
                case .normal:
                    unstakeButton.isUserInteractionEnabled = true
                    unstakeButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
                case .disable:
                    unstakeButton.isUserInteractionEnabled = false
                    unstakeButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .normal)
                case .approve:
                    unstakeButton.isUserInteractionEnabled = true
                    unstakeButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeData()
        setupUI()
    }
    
    func initializeData() {
        if let viewModel = viewModel {
            viewModel.delegate = self
            viewModel.fetchData()
        }
    }
    
    func setupUI() {
        guard let viewModel = viewModel else { return }
        availableUnstakeValue.text = viewModel.displayDepositedValue
        amountTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        receiveInfoView.setInfo(title: "You will receive", value: viewModel.receivedValueString())
        rateView.setInfo(title: "Rate", value: viewModel.showRateInfo(), shouldShowIcon: true)
        networkFeeView.setInfo(title: "Network Fee", value: viewModel.transactionFeeString())
        receiveTimeView.setInfo(title: viewModel.timeForUnstakeString(), value: "")
    }
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func settingButtonTapped(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        TransactionSettingPopup.show(on: self, chain: viewModel.chain, currentSetting: viewModel.setting, onConfirmed: { [weak self] settingObject in
            self?.viewModel?.setting = settingObject
            self?.networkFeeView.setInfo(title: "Network Fee", value: viewModel.transactionFeeString())
        }, onCancelled: {
            return
        })
    }
    
    @IBAction func maxButtonTapped(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        viewModel.unstakeValue = viewModel.balance
        amountTextField.text = viewModel.unstakeValueString()
        receiveInfoView.setValue(value: viewModel.receivedValueMaxString() + " " + viewModel.toTokenSymbol)
    }
    
    @IBAction func unstakeButtonTapped(_ sender: Any) {
        switch unstakeButtonState {
            case .normal:
                unstake()
            default:
                approve()
        }
    }
    
    func showError() {
        amountView.shakeViewError()
        amountViewBottomConstraint.constant = 54
        receiveTimeView.isHidden = true
    }
    
    func hideError() {
        amountView.removeError()
        amountViewBottomConstraint.constant = 24
        receiveTimeView.isHidden = false
    }
    
    func updateReceivedAmount() {
        guard let viewModel = viewModel else { return }
        viewModel.unstakeValue = amountTextField.text?.amountBigInt(decimals: 18) ?? BigInt(0)
        receiveInfoView.setValue(value: viewModel.receivedValueString())
    }
    
    func unstake() {
        
    }
    
    func approve() {
        
    }
}

extension UnstakeViewController: UnstakeViewModelDelegate {
    func didGetDataSuccess() {
        unstakeButtonState = .normal
    }
    
    func didGetDataNeedApproveToken() {
        unstakeButtonState = .approve
    }
    
    func didGetDataFail(errMsg: String) {
        self.showErrorTopBannerMessage(message: errMsg)
    }
}

extension UnstakeViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateReceivedAmount()
    }

}
