//
//  StakingViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 26/10/2022.
//

import UIKit
import BigInt
import Utilities
import AppState
import Services
import DesignSystem
import Dependencies
import TransactionModule
import FittedSheets

typealias ProjectionValue = (value: String, usd: String)
typealias ProjectionValues = (p30: ProjectionValue, p60: ProjectionValue, p90: ProjectionValue)

enum FormState: Equatable {
    case valid
    case error(msg: String)
    case empty
    
    static public func == (lhs: FormState, rhs: FormState) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid), (.empty, .empty):
            return true
        default:
            return false
        }
    }
}

enum NextButtonState {
    case notApprove
    case needApprove
    case approved
    case noNeed
}

class StakingViewController: InAppBrowsingViewController {
    
    @IBOutlet weak var stakeMainHeaderLabel: UILabel!
    @IBOutlet weak var stakeTokenLabel: UILabel!
    @IBOutlet weak var stakeTokenImageView: UIImageView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var apyInfoView: SwapInfoView!
    @IBOutlet weak var amountReceiveInfoView: SwapInfoView!
    @IBOutlet weak var rateInfoView: SwapInfoView!
    @IBOutlet weak var networkFeeInfoView: SwapInfoView!
    
    @IBOutlet weak var earningTokenContainerView: StakingEarningTokensView!
    @IBOutlet weak var infoAreaTopContraint: NSLayoutConstraint!
    @IBOutlet weak var errorMsgLabel: UILabel!
    @IBOutlet weak var amountFieldContainerView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var expandProjectionButton: UIButton!
    @IBOutlet weak var expandContainerViewHeightContraint: NSLayoutConstraint!
    
    @IBOutlet weak var p30ValueLabel: UILabel!
    @IBOutlet weak var p30USDValueLabel: UILabel!
    
    @IBOutlet weak var p60ValueLabel: UILabel!
    @IBOutlet weak var p60USDValueLabel: UILabel!
    
    @IBOutlet weak var p90ValueLabel: UILabel!
    @IBOutlet weak var p90USDValueLabel: UILabel!
    
    @IBOutlet weak var projectionContainerView: UIView!
    
    @IBOutlet weak var pendingTxIndicator: UIView!
    
    var viewModel: StakingViewModel!
    var keyboardTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindingViewModel()
        viewModel.requestOptionDetail()
        viewModel.getAllowance()
        updateUIProjection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        onPendingTxListUpdated()
    }
    
    override func observeNotifications() {
        super.observeNotifications()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPendingTxListUpdated),
            name: .kPendingTxListUpdated,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .kPendingTxListUpdated, object: nil)
    }
    
    @objc func onPendingTxListUpdated() {
        pendingTxIndicator.isHidden = !TransactionManager.txProcessor.hasPendingTx()
    }
    
    private func setupUI() {
        apyInfoView.setTitle(title: Strings.apyTitle, underlined: false)
        //    apyInfoView.iconImageView.isHidden = true
        
        amountReceiveInfoView.setTitle(title: Strings.youWillReceive, underlined: false)
        //    amountReceiveInfoView.iconImageView.isHidden = true
        
        rateInfoView.setTitle(title: Strings.rate, underlined: false, shouldShowIcon: true)
        rateInfoView.onTapRightIcon = {
            self.viewModel.isUseReverseRate.value = !self.viewModel.isUseReverseRate.value
        }
        
        networkFeeInfoView.setTitle(title: Strings.networkFee, underlined: false)
        //    networkFeeInfoView.iconImageView.isHidden = true
        
        earningTokenContainerView.delegate = self
        updateUIGasFee()
    }
    
    fileprivate func updateRateInfoView() {
        self.amountReceiveInfoView.setValue(value: self.viewModel.displayAmountReceive)
        self.rateInfoView.setValue(value: self.viewModel.displayRate)
    }
    
    fileprivate func updateUIEarningTokenView() {
        if let data = viewModel.optionDetail.value, data.count <= 1 {
            earningTokenContainerView.isHidden = true
            infoAreaTopContraint.constant = 40
        } else {
            earningTokenContainerView.isHidden = false
            infoAreaTopContraint.constant = 211
        }
    }
    
    fileprivate func updateUIError() {
        switch viewModel.formState.value {
        case .valid:
            amountFieldContainerView.rounded(radius: 16)
            errorMsgLabel.text = ""
            nextButton.alpha = 1
            nextButton.isEnabled = true
        case .error(let msg):
            amountFieldContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
            errorMsgLabel.text = msg
            nextButton.alpha = 0.2
        case .empty:
            amountFieldContainerView.rounded(radius: 16)
            errorMsgLabel.text = ""
            nextButton.alpha = 0.2
        }
    }
    
    fileprivate func updateUIGasFee() {
        networkFeeInfoView.setValue(value: viewModel.displayFeeString)
    }
    
    fileprivate func updateUIProjection() {
        guard let projectionData = viewModel.displayProjectionValues else {
            projectionContainerView.isHidden = true
            return
        }
        p30ValueLabel.text = projectionData.p30.value
        p30USDValueLabel.text = projectionData.p30.usd
        
        p60ValueLabel.text = projectionData.p60.value
        p60USDValueLabel.text = projectionData.p60.usd
        
        p90ValueLabel.text = projectionData.p90.value
        p90USDValueLabel.text = projectionData.p90.usd
        
        projectionContainerView.isHidden = false
        viewModel.isExpandProjection.value = true
    }
    
    private func bindingViewModel() {
        stakeMainHeaderLabel.text = viewModel.displayMainHeader
        stakeTokenLabel.text = viewModel.displayStakeToken
        stakeTokenImageView.setImage(urlString: viewModel.pool.token.logo, symbol: viewModel.pool.token.symbol)
        apyInfoView.setValue(value: viewModel.displayAPY, highlighted: true)
        viewModel.selectedEarningToken.observeAndFire(on: self) { _ in
            self.updateRateInfoView()
        }
        viewModel.optionDetail.observeAndFire(on: self) { data in
            if let unwrap = data {
                self.earningTokenContainerView.updateData(unwrap)
            }
            self.updateUIEarningTokenView()
        }
        viewModel.amount.observeAndFire(on: self) { _ in
            self.updateRateInfoView()
            self.updateUIError()
            self.viewModel.checkNextButtonStatus()
            self.updateUIProjection()
        }
        viewModel.formState.observeAndFire(on: self) { _ in
            self.updateUIError()
        }
        
        viewModel.txObject.observeAndFire(on: self, observerBlock: { value in
            guard let tx = value else { return }
            print("[Stake] \(tx)")
        })
        
        viewModel.isLoading.observeAndFire(on: self) { value in
            if value {
                self.displayLoading()
            } else {
                self.hideLoading()
                guard !self.viewModel.amount.value.isEmpty else { return }
                self.nextButtonTapped(self.nextButton)
            }
        }
        
        viewModel.gasLimit.observeAndFire(on: self) { _ in
            self.updateUIGasFee()
        }
        
        viewModel.gasPrice.observeAndFire(on: self) { _ in
            self.updateUIGasFee()
        }
        
        viewModel.nextButtonStatus.observeAndFire(on: self) { value in
            switch value {
            case .notApprove:
                self.nextButton.setTitle(String(format: Strings.cheking, self.viewModel.pool.token.symbol), for: .normal)
                self.nextButton.alpha = 0.2
                self.nextButton.isEnabled = false
            case .needApprove:
                self.nextButton.setTitle(String(format: Strings.approveToken, self.viewModel.pool.token.symbol), for: .normal)
                self.nextButton.alpha = 1
                self.nextButton.isEnabled = true
            case .approved:
                self.nextButton.setTitle(Strings.stakeNow, for: .normal)
                self.updateUIError()
            case .noNeed:
                self.nextButton.setTitle(Strings.stakeNow, for: .normal)
                self.updateUIError()
            }
        }
        
        viewModel.isExpandProjection.observeAndFire(on: self) { value in
            UIView.animate(withDuration: 0.25) {
                if value {
                    self.expandContainerViewHeightContraint.constant = 380.0
                    self.expandProjectionButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                } else {
                    self.expandContainerViewHeightContraint.constant = 48.0
                    self.expandProjectionButton.transform = CGAffineTransform(rotationAngle: 0)
                }
            }
        }
        
        viewModel.isUseReverseRate.observeAndFire(on: self) { _ in
            self.rateInfoView.setValue(value: self.viewModel.displayRate)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func maxButtonTapped(_ sender: UIButton) {
        viewModel.amount.value = AppDependencies.balancesStorage.getBalanceBigInt(address: viewModel.pool.token.address).fullString(decimals: viewModel.pool.token.decimals)
        amountTextField.text = viewModel.amount.value
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        guard viewModel.isChainValid else {
            let chainType = ChainType.make(chainID: viewModel.pool.chainID) ?? .eth
            let alertController = KNPrettyAlertController(
                title: "",
                message: "Please switch to \(chainType.chainName()) to continue".toBeLocalised(),
                secondButtonTitle: Strings.ok,
                firstButtonTitle: Strings.cancel,
                secondButtonAction: {
                    AppState.shared.updateChain(chain: chainType)
                },
                firstButtonAction: {
                }
            )
            alertController.popupHeight = 220
            present(alertController, animated: true, completion: nil)
            return
        }
        if viewModel.nextButtonStatus.value == .needApprove {
            sendApprove(tokenAddress: viewModel.pool.token.address, remain: viewModel.tokenAllowance ?? .zero, symbol: viewModel.pool.token.symbol, toAddress: viewModel.txObject.value?.to ?? "")
        } else {
            guard viewModel.formState.value == .valid else { return }
            if let tx = viewModel.txObject.value {
                let displayInfo = StakeDisplayInfo(
                    amount: "\(viewModel.amount.value) \(viewModel.pool.token.symbol)",
                    apy: viewModel.displayAPY,
                    receiveAmount: viewModel.displayAmountReceive,
                    rate: viewModel.displayRate,
                    fee: viewModel.displayFeeString,
                    platform: viewModel.selectedPlatform.name,
                    stakeTokenIcon: viewModel.pool.token.logo,
                    fromSym: viewModel.pool.token.symbol,
                    toSym: viewModel.selectedEarningToken.value?.symbol ?? ""
                )
                self.openStakeSummary(txObject: tx, settings: viewModel.setting, displayInfo: displayInfo)
            } else {
                viewModel.requestBuildStakeTx(showLoading: true)
            }
        }
        
    }
    
    @IBAction func expandProjectionButtonTapped(_ sender: UIButton) {
        viewModel.isExpandProjection.value = !viewModel.isExpandProjection.value
    }
    
    func sendApprove(tokenAddress: String, remain: BigInt, symbol: String, toAddress: String) {
        let vm = ApproveTokenViewModel(symbol: symbol, tokenAddress: tokenAddress, remain: remain, toAddress: toAddress, chain: AppState.shared.currentChain)
        let vc = ApproveTokenViewController(viewModel: vm)
        vc.onSuccessApprove = {
            self.viewModel.nextButtonStatus.value = .approved
        }
        
        vc.onFailApprove = {
            self.viewModel.nextButtonStatus.value = .notApprove
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    func openStakeSummary(txObject: TxObject, settings: TxSettingObject, displayInfo: StakeDisplayInfo) {
        guard let earningToken = viewModel.selectedEarningToken.value else { return }
        let viewModel = StakingSummaryViewModel(earnToken: earningToken, txObject: txObject, setting: settings, pool: viewModel.pool, platform: viewModel.selectedPlatform, displayInfo: displayInfo)
        TxConfirmPopup.show(onViewController: self, withViewModel: viewModel) { [weak self] pendingTx in
            self?.openTxStatusPopup(tx: pendingTx as! PendingStakingTxInfo)
        }
    }
    
    func openTxStatusPopup(tx: PendingStakingTxInfo) {
        let popup = StakingTrasactionProcessPopup.instantiateFromNib()
        popup.tx = tx
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(420)], options: .init(pullBarHeight: 0))
        dismiss(animated: true) {
            UIApplication.shared.topMostViewController()?.present(sheet, animated: true)
        }
    }
    
}

extension StakingViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        self.viewModel.amount.value = ""
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        let cleanedText = text.cleanStringToNumber()
        if cleanedText.amountBigInt(decimals: self.viewModel.pool.token.decimals) == nil { return false }
        textField.text = cleanedText
        self.viewModel.amount.value = cleanedText
        self.keyboardTimer?.invalidate()
        self.keyboardTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(StakingViewController.keyboardPauseTyping),
            userInfo: ["textField": textField],
            repeats: false)
        return false
    }
    
    @objc func keyboardPauseTyping(timer: Timer) {
        updateRateInfoView()
        viewModel.requestBuildStakeTx()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        showWarningInvalidAmountDataIfNeeded()
    }
    
    fileprivate func showWarningInvalidAmountDataIfNeeded() {
        guard !self.viewModel.amount.value.isEmpty else {
            viewModel.formState.value = .empty
            return
        }
        //    guard self.viewModel.isEnoughFee else {
        //      self.showWarningTopBannerMessage(
        //        with: NSLocalizedString("Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", value: "Insufficient \(KNGeneralProvider.shared.quoteToken) for transaction", comment: ""),
        //        message: String(format: "Deposit more \(KNGeneralProvider.shared.quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), self.viewModel.transactionFee.shortString(units: .ether, maxFractionDigits: 6))
        //      )
        //      return true
        //    }
        
        guard !self.viewModel.isAmountTooSmall else {
            viewModel.formState.value = .error(msg: "amount.to.send.greater.than.zero".toBeLocalised())
            return
        }
        guard !self.viewModel.isAmountTooBig else {
            viewModel.formState.value = .error(msg: "balance.not.enough.to.make.transaction".toBeLocalised())
            return
        }
        viewModel.formState.value = .valid
    }
}

extension StakingViewController: StakingEarningTokensViewDelegate {
    func didSelectEarningToken(_ token: EarningToken) {
        viewModel.selectedEarningToken.value = token
    }
}
