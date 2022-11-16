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
            viewModel.fetchData(controller: self)
        }
    }
    
    func setupUI() {
        guard let viewModel = viewModel else { return }
        availableUnstakeValue.text = viewModel.displayDepositedValue
        amountTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        receiveInfoView.setInfo(title: Strings.youWillReceive, value: viewModel.receivedValueString())
        rateView.setInfo(title: Strings.rate, value: viewModel.showRateInfo(), shouldShowIcon: true, rightValueIcon: Images.revert)
        rateView.onTapRightIcon = { [weak self] in
            self?.viewModel?.showRevertedRate.toggle()
            self?.rateView.setValue(value: viewModel.showRateInfo())
        }
        networkFeeView.setInfo(title: Strings.networkFee, value: viewModel.transactionFeeString())
        receiveTimeView.setInfo(title: viewModel.timeForUnstakeString(), value: "")
        unstakePlatformLabel.text = Strings.Unstake + " " + viewModel.stakingTokenSymbol + " on " + viewModel.platform.name
        tokenIcon.setImage(urlString: viewModel.stakingTokenLogo, symbol: viewModel.stakingTokenSymbol)
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
                openUnStakeSummary()
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
        let inputValue = amountTextField.text?.amountBigInt(decimals: 18) ?? BigInt(0)
        if inputValue > viewModel.balance {
            showError()
            return
        } else {
            hideError()
        }
        viewModel.unstakeValue = inputValue
        receiveInfoView.setValue(value: viewModel.receivedValueString())
    }
    
    func openUnStakeSummary() {
        guard let viewModel = viewModel else { return }
        viewModel.requestBuildUnstakeTx(completion: {
            if let tx = viewModel.txObject {
                
                let displayInfo = UnstakeDisplayInfo(amount: viewModel.unstakeValueString() + " " + viewModel.stakingTokenSymbol,
                                                     receiveAmount: viewModel.receivedValueString(),
                                                     rate: viewModel.showRateInfo(),
                                                     fee: viewModel.transactionFeeString(),
                                                     stakeTokenIcon: viewModel.stakingTokenLogo,
                                                     toTokenIcon: viewModel.toTokenLogo,
                                                     fromSym: viewModel.stakingTokenSymbol,
                                                     toSym: viewModel.toTokenSymbol)
                
                
                let viewModel = UnstakeSummaryViewModel(setting: viewModel.setting, txObject: tx, platform: viewModel.platform, displayInfo: displayInfo)
                
                TxConfirmPopup.show(onViewController: self, withViewModel: viewModel) { [weak self] pendingTx in
                    self?.openTxStatusPopup(tx: pendingTx as! PendingUnstakeTxInfo)
                }
            }
        })
    }
    
    func openTxStatusPopup(tx: PendingUnstakeTxInfo) {
        let popup = StakingTrasactionProcessPopup.instantiateFromNib()
        popup.tx = tx
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(420)], options: .init(pullBarHeight: 0))
        dismiss(animated: true) {
            UIApplication.shared.topMostViewController()?.present(sheet, animated: true)
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
            //TODO: show error approve here
            self.showErrorTopBannerMessage(message: "Approve fail")
            self.unstakeButtonState = .normal
        }
        
        self.present(vc, animated: true, completion: nil)
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
