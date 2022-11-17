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
                    unstakeButton.setTitle(String(format: Strings.unstakeToken,viewModel?.stakingTokenSymbol ?? ""), for: .normal)
                case .disable:
                    unstakeButton.isUserInteractionEnabled = false
                    unstakeButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .normal)
                case .approve:
                    unstakeButton.isUserInteractionEnabled = true
                    unstakeButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
                    unstakeButton.setTitle(String(format: Strings.approveToken,viewModel?.stakingTokenSymbol ?? ""), for: .normal)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeData()
        setupUI()
    }
    
    func initializeData() {
        unstakeButtonState = .disable
        if let viewModel = viewModel {
            viewModel.delegate = self
            self.showLoadingHUD()
            viewModel.fetchData {
                self.hideLoading()
            }
        }
    }
    
    func setupUI() {
        guard let viewModel = viewModel else { return }
        availableUnstakeValue.text = viewModel.displayDepositedValue
        amountTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        receiveInfoView.setInfo(title: Strings.youWillReceive, value: viewModel.receivedInfoString())
        rateView.setInfo(title: Strings.rate, value: viewModel.showRateInfo(), shouldShowIcon: true, rightValueIcon: Images.revert)
        rateView.onTapRightIcon = { [weak self] in
            self?.viewModel?.showRevertedRate.toggle()
            self?.rateView.setValue(value: viewModel.showRateInfo())
        }
        networkFeeView.setInfo(title: Strings.networkFee, value: viewModel.transactionFeeString())
        receiveTimeView.setInfo(title: viewModel.timeForUnstakeString(), value: "")
        unstakePlatformLabel.text = Strings.unstake + " " + viewModel.stakingTokenSymbol + " on " + viewModel.platform.name
        tokenIcon.setImage(urlString: viewModel.stakingTokenLogo, symbol: viewModel.stakingTokenSymbol)
        viewModel.onGasSettingUpdated = { [weak self] in
            self?.updateUIGasFee()
        }
    }
    
    fileprivate func updateUIGasFee() {
        guard let viewModel = viewModel else { return }
        networkFeeView.setValue(value: viewModel.transactionFeeString())
    }
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func settingButtonTapped(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        TransactionSettingPopup.show(on: self, chain: viewModel.chain, currentSetting: viewModel.setting, onConfirmed: { [weak self] settingObject in
            self?.viewModel?.setting = settingObject
            self?.networkFeeView.setInfo(title: Strings.networkFee, value: viewModel.transactionFeeString())
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
                viewModel?.openUnStakeSummary(controller: self)
            default:
                viewModel?.approve(controller: self, onSuccess: {
                    self.unstakeButtonState = .normal
                }, onFail: {
                    self.showErrorTopBannerMessage(message: "Approve fail")
                    self.unstakeButtonState = .normal
                })
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
        let inputValue = amountTextField.text?.amountBigInt(decimals: 18) ?? BigInt(0)
        if inputValue > viewModel.balance {
            showError()
            return
        } else {
            hideError()
        }
        viewModel.unstakeValue = inputValue
        receiveInfoView.setValue(value: viewModel.receivedInfoString())
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
