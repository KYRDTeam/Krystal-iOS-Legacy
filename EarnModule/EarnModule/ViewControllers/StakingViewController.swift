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
import AppState
import Result

typealias ProjectionValue = (value: String, usd: String)
typealias ProjectionValues = (p30: ProjectionValue, p60: ProjectionValue, p90: ProjectionValue)

enum FormState: Equatable {
    case valid
    case error(error: StakingValidationError)
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
    case approving
    case approved
    case noNeed
}

class StakingViewController: InAppBrowsingViewController {
    @IBOutlet weak var balanceTitleLabel: UILabel!
    @IBOutlet weak var stakeMainHeaderLabel: UILabel!
    @IBOutlet weak var stakeTokenLabel: UILabel!
    @IBOutlet weak var stakeTokenImageView: UIImageView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var apyInfoView: TxInfoView!
    @IBOutlet weak var amountReceiveInfoView: TxInfoView!
    @IBOutlet weak var rateInfoView: TxInfoView!
    @IBOutlet weak var networkFeeInfoView: TxInfoView!
    
    @IBOutlet weak var earningTokenContainerView: StakingEarningTokensView!
    @IBOutlet weak var infoAreaTopContraint: NSLayoutConstraint!
    @IBOutlet weak var errorMsgLabel: UILabel!
    @IBOutlet weak var amountFieldContainerView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var expandProjectionButton: UIButton!
    @IBOutlet weak var expandContainerViewHeightContraint: NSLayoutConstraint!
    
    @IBOutlet weak var projectionTitleLabel: UILabel!
    @IBOutlet weak var p30ValueLabel: UILabel!
    @IBOutlet weak var p30USDValueLabel: UILabel!
    @IBOutlet weak var p60ValueLabel: UILabel!
    @IBOutlet weak var p60USDValueLabel: UILabel!
    @IBOutlet weak var p90ValueLabel: UILabel!
    @IBOutlet weak var p90USDValueLabel: UILabel!
    @IBOutlet weak var projectionContainerView: UIView!
    @IBOutlet weak var pendingTxIndicator: UIView!
  
    @IBOutlet weak var faqContainerView: StakingFAQView!
    @IBOutlet weak var faqContainerHeightContraint: NSLayoutConstraint!
    
    @IBOutlet weak var earningTokensHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ethWarningView: UIView!
    @IBOutlet weak var nextButtonTopContraint: NSLayoutConstraint!
    
    var viewModel: StakingViewModel!
    var keyboardTimer: Timer?
    var onSelectViewPool: (() -> ())?
    
    override var allowSwitchChain: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindingViewModel()
        viewModel.observeEvents()
        viewModel.requestOptionDetail()
        viewModel.getAllowance()
        viewModel.getQuoteTokenPrice()
        viewModel.getStakingTokenDetail()
        updateUIProjection()
        faqContainerView.updateFAQInput(viewModel.faqInput)
        faqContainerView.delegate = self
        updateUIETHWarningView()
        AppDependencies.tracker.track(
            viewModel.earningType == .staking ? "earn_v2_stake_setup_open" : "earn_v2_supply_setup_open",
            properties: ["screenid": viewModel.earningType == .staking ? "earn_v2_stake_setup" : "earn_v2_supply_setup"]
        )
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
    
    override func onAppSwitchAddress(switchChain: Bool) {
        if !switchChain {
            super.onAppSwitchAddress(switchChain: switchChain)
            viewModel.reloadData()
        }
    }
    
    override func onAppSwitchChain() {
        super.onAppSwitchChain()
        viewModel.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .kPendingTxListUpdated, object: nil)
    }
    
    @objc func onPendingTxListUpdated() {
        pendingTxIndicator.isHidden = !TransactionManager.txProcessor.hasPendingTx()
    }
    
    private func setupUI() {
        balanceTitleLabel.text = viewModel.balanceTitleString
        stakeMainHeaderLabel.text = viewModel.titleString
        projectionTitleLabel.text = viewModel.projectionTitleString
        
        amountTextField.setPlaceholder(text: Strings.amount, color: AppTheme.current.secondaryTextColor)
        
        apyInfoView.setTitle(title: Strings.apyTitle, underlined: false)
        
        amountReceiveInfoView.setTitle(title: Strings.youWillReceive, underlined: false)
        
        rateInfoView.setInfo(title: Strings.rate, titleUnderlined: false, value: "", shouldShowIcon: true, rightValueIcon: Images.revert)
        rateInfoView.onTapRightIcon = {
            self.viewModel.isUseReverseRate.value = !self.viewModel.isUseReverseRate.value
        }
        
        networkFeeInfoView.setTitle(title: Strings.networkFee, underlined: false)
        
        earningTokenContainerView.delegate = self
        updateUIGasFee()
    }
    
    fileprivate func updateRateInfoView() {
        self.amountReceiveInfoView.setValue(value: self.viewModel.displayAmountReceive)
        self.rateInfoView.setValue(value: self.viewModel.displayRate)
    }
    
    fileprivate func updateUIETHWarningView() {
        guard AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.unstakeWarning) else {
            return
        }
        guard viewModel.token.address == Constants.ethAddress && viewModel.earningType == .staking else {
            return
        }
        
        ethWarningView.isHidden = false
        nextButtonTopContraint.constant = 180
    }
    
    fileprivate func updateUIEarningTokenView() {
        let data = viewModel.optionDetail.value?.earningTokens
        if data == nil || data!.count <= 1 {
            earningTokenContainerView.isHidden = true
            infoAreaTopContraint.constant = 40
        } else {
            let maxEarningTokenCellHeight: CGFloat = viewModel.optionDetail.value?.earningTokens.map {
                return getEarningTokenHeight(text: $0.desc)
            }.max() ?? 0
            earningTokenContainerView.isHidden = false
            infoAreaTopContraint.constant = maxEarningTokenCellHeight + 40 + 52
            earningTokensHeightConstraint.constant = maxEarningTokenCellHeight + 32
            view.layoutIfNeeded()
        }
    }
    
    fileprivate func updateUIError() {
        guard !AppState.shared.isBrowsingMode else {
            self.nextButton.setTitle(String(format: Strings.connectWallet, self.viewModel.token.symbol), for: .normal)
            self.nextButton.alpha = 1
            self.nextButton.isEnabled = true
            return
        }
        guard !AppState.shared.currentAddress.isWatchWallet else {
            self.nextButton.setTitle(Strings.stakeNow, for: .normal)
            self.nextButton.alpha = 0.2
            self.nextButton.isEnabled = false
            return
        }
        switch viewModel.formState.value {
        case .valid:
            amountFieldContainerView.rounded(radius: 16)
            errorMsgLabel.text = ""
            nextButton.alpha = 1
            nextButton.isEnabled = true
        case .error(let error):
            amountFieldContainerView.rounded(color: AppTheme.current.errorTextColor, width: 1, radius: 16)
            errorMsgLabel.text = viewModel.messageFor(validationError: error)
            nextButton.alpha = 0.2
        case .empty:
            amountFieldContainerView.rounded(radius: 16)
            errorMsgLabel.text = ""
            nextButton.alpha = 0.2
        }
    }
    
    private func getEarningTokenHeight(text: String) -> CGFloat {
        let width = (view.frame.width - 56) / 2 - 40
        return text.height(withConstrainedWidth: width, font: .karlaReguler(ofSize: 14)) + 68
    }
    
    fileprivate func updateUIGasFee() {
        networkFeeInfoView.setValue(value: viewModel.displayFeeString)
    }
    
    fileprivate func updateUIProjection() {
        guard let projectionData = viewModel.displayProjectionValues else {
            projectionContainerView.isHidden = true
            viewModel.isExpandProjection.value = false
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
        stakeTokenImageView.setImage(urlString: viewModel.token.logo, symbol: viewModel.token.symbol)
        apyInfoView.setValue(value: viewModel.displayAPY, highlighted: true)
        
        viewModel.balance.observeAndFire(on: self) { [weak self] _ in
            self?.stakeTokenLabel.text = self?.viewModel.displayStakeToken
        }
        
        viewModel.selectedEarningToken.observeAndFire(on: self) { _ in
            self.updateRateInfoView()
            self.faqContainerView.updateFAQInput(self.viewModel.faqInput)
        }
        viewModel.optionDetail.observeAndFire(on: self) { data in
            if let unwrap = data {
                self.earningTokenContainerView.updateData(unwrap.earningTokens)
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
        
        viewModel.isLoading.observeAndFire(on: self) { value in
            if value {
                self.displayLoading()
            } else {
                self.hideLoading()
            }
        }
        
        viewModel.error.observe(on: self) { [weak self] value in
            self?.showTopBannerView(message: value?.localizedDescription ?? Strings.defaultErrorMessage)
        }
        
        viewModel.gasLimit.observeAndFire(on: self) { _ in
            self.updateUIGasFee()
        }
        viewModel.nextButtonStatus.observeAndFire(on: self) { [weak self] value in
            guard let self = self else { return }
            guard !AppState.shared.isBrowsingMode else {
                self.nextButton.setTitle(String(format: Strings.connectWallet, self.viewModel.token.symbol), for: .normal)
                self.nextButton.alpha = 1
                self.nextButton.isEnabled = true
                return
            }
            guard !AppState.shared.currentAddress.isWatchWallet else {
                self.nextButton.setTitle(Strings.stakeNow, for: .normal)
                self.nextButton.alpha = 0.2
                self.nextButton.isEnabled = false
                return
            }
            switch value {
            case .notApprove:
                self.nextButton.setTitle(String(format: Strings.checking, self.viewModel.token.symbol), for: .normal)
                self.nextButton.alpha = 0.2
                self.nextButton.isEnabled = false
            case .needApprove:
                self.nextButton.setTitle(String(format: Strings.approveToken, self.viewModel.token.symbol), for: .normal)
                self.nextButton.alpha = 1
                self.nextButton.isEnabled = true
            case .approved:
                self.nextButton.setTitle(self.viewModel.actionButtonTitle, for: .normal)
                self.updateUIError()
            case .approving:
                self.nextButton.setTitle(Strings.approveInProgress, for: .normal)
                self.nextButton.alpha = 0.2
                self.nextButton.isEnabled = false
            case .noNeed:
                self.nextButton.setTitle(self.viewModel.actionButtonTitle, for: .normal)
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
        
        viewModel.onFetchedQuoteTokenPrice = { [weak self] in
            self?.updateUIGasFee()
        }
        
        faqContainerView.isExpand.observeAndFire(on: self) { value in
            if value {
                self.faqContainerHeightContraint.constant = 50
            } else {
              self.faqContainerHeightContraint.constant = self.faqContainerView.currentHeight ?? self.faqContainerView.getViewHeight()
            }
        }
        
        viewModel.onGasSettingUpdated = { [weak self] in
            self?.updateUIGasFee()
        }
    }
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        let chainType = ChainType.make(chainID: viewModel.chainId) ?? .eth
        TransactionSettingPopup.show(on: self, chain: chainType, currentSetting: viewModel.setting, onConfirmed: { [weak self] settingObject in
            self?.viewModel.setting = settingObject
            self?.updateUIGasFee()
        }, onCancelled: {
            return
        })
    }

    @IBAction func historyTapped(_ sender: Any) {
        AppDependencies.router.openTransactionHistory()
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func maxButtonTapped(_ sender: UIButton) {
        viewModel.amount.value = viewModel.maxStakableAmount
        amountTextField.text = NumberFormatUtils.amount(value: viewModel.maxStakableAmount, decimals: viewModel.token.decimals)
        showWarningInvalidAmountDataIfNeeded()
        viewModel.requestBuildStakeTx()
        if viewModel.isUsingQuoteToken {
            showSuccessTopBannerMessage(
                message: String(format: Strings.amountQuoteTokenUsedForFee, viewModel.currentChain.quoteToken())
            )
        }
        AppDependencies.tracker.track(
            viewModel.earningType == .staking ? "mob_stake_max_amount" : "mob_supply_max_amount",
            properties:["screenid": viewModel.earningType == .staking ? "earn_v2_stake_setup" : "earn_v2_supply_setup"]
        )

    }
    
    func showSwitchChainPopup() {
        let chainType = ChainType.make(chainID: viewModel.chainId) ?? .eth
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
    }
    
    func openStakeSummary(txObject: TxObject) {
        let amountString = NumberFormatUtils.amount(value: viewModel.amount.value, decimals: viewModel.token.decimals)
        let displayInfo = StakeDisplayInfo(
            amount: "\(amountString) \(viewModel.token.symbol)",
            apy: viewModel.displayAPY,
            receiveAmount: viewModel.displayAmountReceive,
            rate: viewModel.displayRate,
            fee: viewModel.displayFeeString,
            platform: viewModel.selectedPlatform.name,
            stakeTokenIcon: viewModel.token.logo,
            fromSym: viewModel.token.symbol,
            toSym: viewModel.selectedEarningToken.value?.symbol ?? ""
        )
        self.openStakeSummary(txObject: txObject, settings: viewModel.setting, displayInfo: displayInfo)
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        guard !AppState.shared.isBrowsingMode else {
          onAddWalletButtonTapped(sender)
          return
        }
        guard viewModel.isChainValid else {
            showSwitchChainPopup()
            return
        }
        if viewModel.nextButtonStatus.value == .needApprove {
            sendApprove(tokenAddress: viewModel.token.address, remain: viewModel.tokenAllowance ?? .zero, symbol: viewModel.token.symbol, toAddress: viewModel.txObject.value?.to ?? "")
        } else {
            guard viewModel.formState.value == .valid else { return }
            guard !self.viewModel.amount.value.isZero else { return }
            viewModel.requestBuildStakeTx(showLoading: true) { [weak self] success in
                guard let txObject = self?.viewModel.txObject.value else { return }
                self?.openStakeSummary(txObject: txObject)
            }
        }
        var params = ["screenid": viewModel.earningType == .staking ? "earn_v2_stake_setup" : "earn_v2_supply_setup"]
        params["earn_amount"] = viewModel.amount.value.description
        params["earn_token"] = viewModel.selectedEarningToken.value?.symbol
        params["earn_platform"] = viewModel.selectedPlatform.name
        AppDependencies.tracker.track(
            viewModel.earningType == .staking ? "mob_stake" : "mob_supply",
            properties: params
        )
    }
    
    @IBAction func expandProjectionButtonTapped(_ sender: UIButton) {
        viewModel.isExpandProjection.value = !viewModel.isExpandProjection.value
    }
    
    func sendApprove(tokenAddress: String, remain: BigInt, symbol: String, toAddress: String) {
        let vm = ApproveTokenViewModel(symbol: symbol, tokenAddress: tokenAddress, remain: remain, toAddress: toAddress, chain: AppState.shared.currentChain)
        let vc = ApproveTokenViewController(viewModel: vm)
        vc.onApproveSent = { hash in
            self.viewModel?.approveHash = hash
            self.viewModel.nextButtonStatus.value = .approving
        }
        vc.onFailApprove = { [weak self] error in
          self?.showTopBannerView(message: TxErrorParser.parse(error: AnyError(error)).message)
          self?.viewModel.nextButtonStatus.value = .needApprove
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    func openStakeSummary(txObject: TxObject, settings: TxSettingObject, displayInfo: StakeDisplayInfo) {
        guard let earningToken = viewModel.selectedEarningToken.value else { return }
        let viewModel = StakingSummaryViewModel(earnToken: earningToken, txObject: txObject, setting: settings, token: viewModel.token, platform: viewModel.selectedPlatform, displayInfo: displayInfo)
        TxConfirmPopup.show(onViewController: self, withViewModel: viewModel) { [weak self] pendingTx in
            AppDependencies.tracker.track(
                viewModel.earningType == .staking ? "mob_confirm_stake" : "mob_confirm_supply",
                properties: ["screenid": viewModel.earningType == .staking ? "earn_v2_stake_confirm" : "earn_v2_supply_confirm"]
            )
            self?.openTxStatusPopup(tx: pendingTx as! PendingStakingTxInfo)
        }
    }
    
    func openTxStatusPopup(tx: PendingStakingTxInfo) {
        let popup = StakingTrasactionProcessPopup.instantiateFromNib()
        let viewModel = StakingTransactionProcessPopupViewModel(pendingStakingTx: tx)
        popup.viewModel = viewModel
        popup.onSelectViewPool = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            self?.onSelectViewPool?()
        }
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(420)], options: .init(pullBarHeight: 0))
        dismiss(animated: true) {
            UIApplication.shared.topMostViewController()?.present(sheet, animated: true)
        }
    }
    
}

extension StakingViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        self.viewModel.amount.value = .zero
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        let cleanedText = text.cleanStringToNumber()
        if cleanedText.amountBigInt(decimals: self.viewModel.token.decimals) == nil { return false }
        textField.text = cleanedText
        self.viewModel.amount.value = BigInt((cleanedText.toDouble() ?? 0) * pow(10.0, Double(viewModel.token.decimals)))
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
        AppDependencies.tracker.track(
            viewModel.earningType == .staking ? "mob_enter_stake_amount" : "mob_enter_supply_amount",
            properties: ["screenid": viewModel.earningType == .staking ? "earn_v2_stake_setup" : "earn_v2_supply_setup"]
        )
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        showWarningInvalidAmountDataIfNeeded()
    }
    
    fileprivate func showWarningInvalidAmountDataIfNeeded() {
        guard !self.viewModel.amount.value.isZero else {
            viewModel.formState.value = .empty
            return
        }
        if let error = viewModel.validateAmount() {
            viewModel.formState.value = .error(error: error)
        } else {
            viewModel.formState.value = .valid
        }
    }
}

extension StakingViewController: StakingEarningTokensViewDelegate {
    func didSelectEarningToken(_ token: EarningToken) {
        viewModel.selectedEarningToken.value = token
        viewModel.requestBuildStakeTx()
    }
}

extension StakingViewController: StakingFAQViewDelegate {
  func viewShouldChangeHeight(height: CGFloat) {
    faqContainerHeightContraint.constant = height
  }
}
