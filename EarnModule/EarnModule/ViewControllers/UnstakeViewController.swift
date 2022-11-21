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
import FittedSheets
import Utilities

enum UnstakeButtonState {
    case normal
    case disable
    case approve
    case insufficientFee
}

class UnstakeViewController: InAppBrowsingViewController {
    @IBOutlet weak var unstakePlatformLabel: UILabel!
    @IBOutlet weak var availableUnstakeValue: UILabel!
    @IBOutlet weak var unstakeButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var tokenIcon: UIImageView!
    @IBOutlet weak var amountViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var amountView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
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
                    unstakeButton.setTitle(String(format: Strings.unstakeToken,viewModel?.stakingTokenSymbol ?? ""), for: .normal)
                case .insufficientFee:
                    unstakeButton.isUserInteractionEnabled = false
                    unstakeButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .normal)
                    unstakeButton.setTitle(String(format: Strings.insufficientQuoteBalance,viewModel?.chain.quoteToken() ?? ""), for: .normal)
                case .approve:
                    unstakeButton.isUserInteractionEnabled = true
                    unstakeButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
                    unstakeButton.setTitle(String(format: Strings.approveToken,viewModel?.stakingTokenSymbol ?? ""), for: .normal)
            }
        }
    }
    override var allowSwitchChain: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeData()
        setupUI()
        updateUINextButton()
    }
    
    func initializeData() {
        unstakeButtonState = .disable
        if let viewModel = viewModel {
            viewModel.delegate = self
            self.showLoadingHUD()
            viewModel.fetchData {
                self.hideLoading()
            }
            viewModel.getQuoteTokenPrice()
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
        unstakePlatformLabel.text = Strings.unstake + " " + viewModel.stakingTokenSymbol + " on " + viewModel.platform.name.uppercased()
        tokenIcon.setImage(urlString: viewModel.stakingTokenLogo, symbol: viewModel.stakingTokenSymbol)
        viewModel.onGasSettingUpdated = { [weak self] in
            self?.updateUIGasFee()
        }
        
        viewModel.onFetchedQuoteTokenPrice = { [weak self] in
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
        validateInput()
        updateUINextButton()
    }
    
    @IBAction func unstakeButtonTapped(_ sender: Any) {
        updateReceivedAmount()
        if validateInput() {
            switch unstakeButtonState {
                case .normal:
                    openUnStakeSummary()
                default:
                    approve()
                    unstakeButtonState = .disable
            }
        }
    }
    
    func showError(msg: String) {
        amountView.shakeViewError()
        amountViewBottomConstraint.constant = 54
        receiveTimeView.isHidden = true
        errorLabel.text = msg
        errorLabel.isHidden = false
    }
    
    func hideError() {
        amountView.removeError()
        amountViewBottomConstraint.constant = 24
        receiveTimeView.isHidden = false
        errorLabel.text = ""
        errorLabel.isHidden = false
    }
    
    func updateReceivedAmount() {
        guard let viewModel = viewModel else { return }
        let inputValue = amountTextField.text?.amountBigInt(decimals: 18) ?? BigInt(0)
        viewModel.unstakeValue = inputValue
        receiveInfoView.setValue(value: viewModel.receivedInfoString())
    }
    
    func validateInput() -> Bool {
        guard let viewModel = viewModel else { return false }
        let inputValue = amountTextField.text?.amountBigInt(decimals: 18) ?? BigInt(0)
        let convertedMaxBalance = viewModel.balance
        let convertedMin = viewModel.minUnstakeAmount * BigInt(10).power(18) / viewModel.ratio
        let convertedMax = viewModel.maxUnstakeAmount * BigInt(10).power(18) / viewModel.ratio
        
        //convert and round up last number < copy logic android>
        let convertedMinString = String(format: "%6f", convertedMin.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 18).doubleValue)
        let convertedMinDouble = Double(convertedMinString) ?? 0
        let inputDouble = inputValue.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 18).doubleValue
        
        if inputValue > convertedMaxBalance {
            showError(msg: Strings.yourStakingBalanceIsNotSufficient)
            return false
        } else if inputValue > convertedMax, convertedMax > BigInt(0) {
            showError(msg: String(format: Strings.shouldNoMoreThan, NumberFormatUtils.amount(value: convertedMax, decimals: 18)) + " " + viewModel.stakingTokenSymbol)
            return false
        }  else if inputDouble < convertedMinDouble {
            showError(msg: String(format: Strings.shouldBeAtLeast, NumberFormatUtils.amount(value: convertedMin, decimals: 18)) + " " + viewModel.stakingTokenSymbol)
            return false
        } else {
            hideError()
            return true
        }
    }
    
    private func updateUINextButton() {
        let inputValue = amountTextField.text?.amountBigInt(decimals: 18) ?? .zero
        if inputValue.isZero {
            unstakeButton.alpha = 0.2
            unstakeButton.isEnabled = false
        } else {
            unstakeButton.alpha = 1
            unstakeButton.isEnabled = true
        }
    }
    
    func approve() {
        guard let viewModel = viewModel, let contractAddress = viewModel.contractAddress else { return }
        let vm = ApproveTokenViewModel(symbol: viewModel.stakingTokenSymbol, tokenAddress: viewModel.stakingTokenAddress, remain: viewModel.stakingTokenAllowance, toAddress: contractAddress, chain: viewModel.chain)
        let vc = ApproveTokenViewController(viewModel: vm)
        vc.onSuccessApprove = {
            self.unstakeButtonState = .normal
        }
        
        vc.onFailApprove = {
            self.showErrorTopBannerMessage(message: "Approve fail")
            self.unstakeButtonState = .approve
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    func openUnStakeSummary() {
        guard let viewModel = viewModel else { return }
        viewModel.requestBuildUnstakeTx(completion: { error in
            guard let error = error else {
                if let tx = viewModel.txObject {
                    let displayInfo = UnstakeDisplayInfo(amount: viewModel.unstakeValueString(),
                                                         receiveAmount: viewModel.receivedValueString(),
                                                         rate: viewModel.showRateInfo(),
                                                         fee: viewModel.transactionFeeString(),
                                                         stakeTokenIcon: viewModel.stakingTokenLogo,
                                                         toTokenIcon:viewModel.toTokenLogo,
                                                         fromSym: viewModel.stakingTokenSymbol,
                                                         toSym: viewModel.toTokenSymbol)
                    
                    
                    let popupViewModel = UnstakeSummaryViewModel(setting: viewModel.setting, txObject: tx, platform: viewModel.platform, displayInfo: displayInfo)
                    
                    TxConfirmPopup.show(onViewController: self, withViewModel: popupViewModel) { pendingTx in
                        if let pendingTx = pendingTx as? PendingUnstakeTxInfo {
                            self.openTxStatusPopup(tx: pendingTx)
                        }
                    }
                }
                return
            }
            self.showErrorTopBannerMessage(message: error.localizedDescription)
        })
    }
        
    func openTxStatusPopup(tx: PendingUnstakeTxInfo) {
        let popup = StakingTrasactionProcessPopup.instantiateFromNib()
        let viewModel = UnstakeTransactionProcessPopupViewModel(pendingStakingTx: tx)
        popup.viewModel = viewModel
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(420)], options: .init(pullBarHeight: 0))
        self.navigationController?.popViewController(animated: true)
        UIApplication.shared.topMostViewController()?.present(sheet, animated: true)
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
    
    func didCheckNotEnoughFeeForTx(errMsg: String) {
        if errMsg.isEmpty {
            unstakeButtonState = .insufficientFee
        } else {
            self.showErrorTopBannerMessage(message: errMsg)
        }
    }
}

extension UnstakeViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else { return }
        updateReceivedAmount()
        validateInput()
        updateUINextButton()
    }

}
