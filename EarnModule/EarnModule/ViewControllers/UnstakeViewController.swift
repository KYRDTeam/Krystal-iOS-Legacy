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
import Services

enum UnstakeButtonState {
    case normal
    case disable
    case needApprove
    case approving
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
    @IBOutlet weak var unstakeBalanceTitleLabel: UILabel!
    @IBOutlet weak var toggleUnwrapView: TxToggleInfoView!

    var viewModel: UnstakeViewModel?
    var unstakeButtonState: UnstakeButtonState = .disable {
        didSet {
            self.configUnstakeButtonUI()
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
            viewModel.observeEvents()
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
        toggleUnwrapView.setTitle(title: String(format: Strings.unwrapToken,viewModel.toTokenSymbol))
        toggleUnwrapView.onSwitchValue = { isOn in
            if let viewModel = self.viewModel {
                viewModel.updateWrapInfo(isUseWrap: isOn)
                self.receiveInfoView.setValue(value: viewModel.receivedValueMaxString() + " " + viewModel.toTokenSymbol)
                self.rateView.setValue(value: viewModel.showRateInfo())
                self.showLoadingHUD()
                viewModel.fetchData(isUseWrapTokenAddress: true, completion: {
                    self.hideLoading()
                })
            }
        }
        
        networkFeeView.setInfo(title: Strings.networkFee, value: viewModel.transactionFeeString())
        receiveTimeView.setInfo(title: viewModel.timeForUnstakeString(), value: "")
        unstakePlatformLabel.text = viewModel.platformTitleString
        unstakeBalanceTitleLabel.text = viewModel.availableBalanceTitleString
        tokenIcon.setImage(urlString: viewModel.stakingTokenLogo, symbol: viewModel.stakingTokenSymbol)
        viewModel.onGasSettingUpdated = { [weak self] in
            self?.updateUIGasFee()
        }
        
        viewModel.onFetchedQuoteTokenPrice = { [weak self] in
            self?.updateUIGasFee()
        }
    }
    
    func configUnstakeButtonUI() {
        guard let viewModel = viewModel else { return }
        switch self.unstakeButtonState {
            case .normal:
                unstakeButton.isUserInteractionEnabled = true
                unstakeButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
                unstakeButton.setTitle(viewModel.buttonTitleString, for: .normal)
            case .disable:
                unstakeButton.isUserInteractionEnabled = false
                unstakeButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .normal)
                unstakeButton.setTitle(viewModel.buttonTitleString, for: .normal)
            case .insufficientFee:
                unstakeButton.isUserInteractionEnabled = false
                unstakeButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .normal)
                unstakeButton.setTitle(String(format: Strings.insufficientQuoteBalance,viewModel.chain.quoteToken()), for: .normal)
            case .needApprove:
                unstakeButton.isUserInteractionEnabled = true
                unstakeButton.setBackgroundColor(AppTheme.current.primaryColor, forState: .normal)
                unstakeButton.setTitle(String(format: Strings.approveToken,viewModel.stakingTokenSymbol), for: .normal)
            case .approving:
                unstakeButton.isUserInteractionEnabled = false
                unstakeButton.setBackgroundColor(AppTheme.current.secondaryButtonBackgroundColor, forState: .normal)
                unstakeButton.setTitle(Strings.approveInProgress, for: .normal)
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
                    unstakeButtonState = .approving
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
        let inputValue = amountTextField.text?.amountBigInt(decimals: viewModel.stakingTokenDecimal) ?? BigInt(0)
        viewModel.unstakeValue = inputValue
        receiveInfoView.setValue(value: viewModel.receivedInfoString())
    }
    
    func validateInput() -> Bool {
        guard let viewModel = viewModel else { return false }
        let decimal = viewModel.stakingTokenDecimal
        let inputValue = amountTextField.text?.amountBigInt(decimals: decimal) ?? BigInt(0)
        let convertedMaxBalance = viewModel.balance
        let convertedMin = viewModel.minUnstakeAmount * BigInt(10).power(decimal) / viewModel.ratio
        let convertedMax = viewModel.maxUnstakeAmount * BigInt(10).power(decimal) / viewModel.ratio
        
        //convert and round up last number < copy logic android>
        let convertedMinString = String(format: "%6f", convertedMin.string(decimals: decimal, minFractionDigits: 0, maxFractionDigits: decimal).doubleValue)
        let convertedMinDouble = Double(convertedMinString) ?? 0
        let inputDouble = inputValue.string(decimals: decimal, minFractionDigits: 0, maxFractionDigits: decimal).doubleValue
        
        if inputValue > convertedMaxBalance {
            showError(msg: Strings.yourStakingBalanceIsNotSufficient)
            return false
        } else if inputValue > convertedMax, convertedMax > BigInt(0) {
            showError(msg: String(format: Strings.shouldNoMoreThan, NumberFormatUtils.amount(value: convertedMax, decimals: decimal)) + " " + viewModel.stakingTokenSymbol)
            return false
        }  else if inputDouble < convertedMinDouble {
            showError(msg: String(format: Strings.shouldBeAtLeast, NumberFormatUtils.amount(value: convertedMin, decimals: decimal)) + " " + viewModel.stakingTokenSymbol)
            return false
        } else {
            hideError()
            return true
        }
    }
    
    private func updateUINextButton() {
        guard let viewModel = viewModel else { return }
        let inputValue = amountTextField.text?.amountBigInt(decimals: viewModel.stakingTokenDecimal) ?? .zero
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
        vc.onDismiss = {
            self.unstakeButtonState = .needApprove
        }
        vc.onApproveSent = { hash in
            self.viewModel?.approveHash = hash
            self.unstakeButtonState = .approving
        }
        vc.onFailApprove = {
            self.showErrorTopBannerMessage(message: Strings.approveFail)
            self.unstakeButtonState = .needApprove
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
                                                         toSym: viewModel.toTokenSymbol,
                                                         earningType: viewModel.earningType)
                    
                    
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
    func didApproveToken(success: Bool) {
        if success {
            self.unstakeButtonState = .normal
        } else {
            self.showErrorTopBannerMessage(message: Strings.approveFail)
            self.unstakeButtonState = .needApprove
        }
    }
    
    func didGetDataSuccess() {
        unstakeButtonState = .normal
    }
    
    func didGetDataNeedApproveToken() {
        unstakeButtonState = .needApprove
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
    
    func didGetWrapInfo(wrap: WrapInfo) {
        toggleUnwrapView.isHidden = !wrap.isWrappable
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
