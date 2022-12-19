//
//  ApproveTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/25/20.
//

import UIKit
import BigInt
import AppState
import Dependencies
import BaseModule
import BaseWallet
import Utilities
import Services
import Loady
import Result

public class ApproveTokenViewController: KNBaseViewController {
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var contractAddressLabel: UILabel!
    @IBOutlet weak var gasFeeTitleLabel: UILabel!
    @IBOutlet weak var gasFeeLabel: UILabel!
    @IBOutlet weak var gasFeeEstUSDLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: LoadyButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var editIcon: UIImageView!
    @IBOutlet weak var editLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var chainIcon: UIImageView!
    @IBOutlet weak var chainLabel: UILabel!
    @IBOutlet weak var actionsToErrorViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionsToGasViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorView: UIView!
    
    var viewModel: ApproveTokenViewModel
    
    public var onDismiss: (() -> Void)? = nil
    public var onApproveSent: ((String) -> Void)? = nil
    
    var approveValue: BigInt {
        return self.viewModel.value
    }
    
    var selectedGasPrice: BigInt {
        return self.viewModel.gasPrice
    }
    
    public init(viewModel: ApproveTokenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ApproveTokenViewController", bundle: Bundle(for: ApproveTokenViewController.self))
        self.modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.confirmButton.setAnimation(LoadyAnimationType.indicator(with: .init(indicatorViewStyle: .black)))
        self.setupChainInfo()
        self.gasFeeLabel.text = self.viewModel.getFeeString()
        self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
        self.cancelButton.rounded(radius: 16)
        self.confirmButton.rounded(radius: 16)
        self.descriptionLabel.text = self.viewModel.subTitleText
        self.contractAddressLabel.text = self.viewModel.toAddress
        if !self.viewModel.showEditSettingButton {
            self.editIcon.isHidden = true
            self.editLabel.isHidden = true
            self.editButton.isHidden = true
        }
        self.headerTitle.text = self.viewModel.headerTitle
    }
    
    func setupChainInfo() {
        chainIcon.image = viewModel.chain.squareIcon()
        chainLabel.text = viewModel.chain.chainName()
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        if viewModel.remain.isZero {
            sendApprove()
        } else {
            showLoading()
            resetAllowanceBeforeSend()
        }
    }
    
    func sendApprove() {
        self.showLoading()
        self.viewModel.sendApproveRequest(value: TransactionConstants.maxTokenAmount) { [weak self] error in
            self?.hideLoading()
            if let error = error {
                self?.showError(message: TxErrorParser.parse(error: AnyError(error)).message)
            } else {
                if let hash = self?.viewModel.hash {
                    self?.onApproveSent?(hash)
                }
                self?.dismiss(animated: true)
            }
        }
    }
    
    func resetAllowanceBeforeSend() {
        self.viewModel.sendApproveRequest(value: BigInt(0)) { [weak self] error in
            if let error = error {
                self?.hideLoading()
                self?.showError(message: TxErrorParser.parse(error: AnyError(error)).message)
            } else {
                self?.sendApprove()
            }
        }
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        TransactionSettingPopup.show(on: self, chain: viewModel.chain, currentSetting: viewModel.setting, onConfirmed: { [weak self] settingObject in
            self?.viewModel.setting = settingObject
            self?.updateGasFeeUI()
        }, onCancelled: {
            return
        })
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        onDismiss?()
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func updateGasFeeUI() {
        self.gasFeeLabel.text = self.viewModel.getFeeString()
        self.gasFeeEstUSDLabel.text = self.viewModel.getFeeUSDString()
    }
    
    public func updateGasLimit(_ gas: BigInt) {
        self.viewModel.gasLimit = gas
        guard self.isViewLoaded else { return }
        updateGasFeeUI()
    }
    
    func showLoading() {
        DispatchQueue.main.async {
            self.cancelButton.isHidden = true
            self.confirmButton.startLoading()
        }
    }
    
    func hideLoading() {
        DispatchQueue.main.async {
            self.cancelButton.isHidden = false
            self.confirmButton.stopLoading()
        }
    }
    
    func showError(message: String) {
        errorView.isHidden = false
        errorLabel.text = message
        actionsToErrorViewConstraint.isActive = true
        actionsToGasViewConstraint.isActive = false
        view.layoutIfNeeded()
        sheetViewController?.updateIntrinsicHeight()
        sheetViewController?.resize(to: .intrinsic)
    }
    
    func hideError() {
        errorView.isHidden = true
        actionsToErrorViewConstraint.isActive = false
        actionsToGasViewConstraint.isActive = true
        view.layoutIfNeeded()
        sheetViewController?.updateIntrinsicHeight()
        sheetViewController?.resize(to: .intrinsic)
    }
}
