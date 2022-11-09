//
//  StakingSummaryViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 31/10/2022.
//

import UIKit
import KrystalWallets
import BigInt
import AppState
import Result
import APIKit
import JSONRPCKit
import DesignSystem
import Services
import Dependencies
import TransactionModule
import FittedSheets

class StakingSummaryViewController: KNBaseViewController {
    
    @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var chainIconImageView: UIImageView!
    @IBOutlet weak var chainNameLabel: UILabel!    
    @IBOutlet weak var tokenIconImageView: UIImageView!
    @IBOutlet weak var tokenNameLabel: UILabel!
    @IBOutlet weak var platformNameLabel: UILabel!
    @IBOutlet weak var apyInfoView: SwapInfoView!
    @IBOutlet weak var receiveAmountInfoView: SwapInfoView!
    @IBOutlet weak var rateInfoView: SwapInfoView!
    @IBOutlet weak var feeInfoView: SwapInfoView!
    
    let viewModel: StakingSummaryViewModel
    
    init(viewModel: StakingSummaryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: StakingSummaryViewController.className, bundle: nil)
        
        self.modalPresentationStyle = .custom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindingViewModel()
    }
    
    private func setupUI() {
        apyInfoView.setTitle(title: "APY (Est. Yield", underlined: false)
        //    apyInfoView.iconImageView.isHidden = true
        
        receiveAmountInfoView.setTitle(title: "You will receive", underlined: false)
        //    receiveAmountInfoView.iconImageView.isHidden = true
        
        rateInfoView.setTitle(title: "Rate", underlined: false, shouldShowIcon: true)
        //    rateInfoView.iconImageView.isHidden = true
        
        feeInfoView.setTitle(title: "Network Fee", underlined: false)
        //    feeInfoView.iconImageView.isHidden = true
        
        let currentChain = AppState.shared.currentChain
        chainIconImageView.image = currentChain.squareIcon()
        chainNameLabel.text = currentChain.chainName()
        
        apyInfoView.setValue(value: viewModel.displayInfo.apy)
        receiveAmountInfoView.setValue(value: viewModel.displayInfo.receiveAmount)
        rateInfoView.setValue(value: viewModel.displayInfo.rate)
        feeInfoView.setValue(value: viewModel.displayInfo.fee)
        
        tokenIconImageView.setImage(urlString: viewModel.displayInfo.stakeTokenIcon, symbol: "")
        tokenNameLabel.text = viewModel.displayInfo.amount
        platformNameLabel.text = "On " + viewModel.displayInfo.platform.uppercased()
        viewModel.onSendTxSuccess = { [weak self] in
            self?.openTxStatusPopup()
        }
    }
    
    private func bindingViewModel() {
        viewModel.shouldDiplayLoading.observeAndFire(on: self) { value in
            if value {
                self.displayLoading()
            } else {
                self.hideLoading()
            }
        }
        
        viewModel.errorMessage.observeAndFire(on: self) { value in
            guard !value.isEmpty else { return }
            self.showTopBannerView(message: value)
        }
    }
    
    func openTxStatusPopup() {
        let popup = StakingTrasactionProcessPopup()
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(420)], options: .init(pullBarHeight: 0))
        dismiss(animated: true) {
            UIApplication.shared.topMostViewController()?.present(sheet, animated: true)
        }
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        viewModel.sendTransaction()
    }
    
    @IBAction func tapOutSidePopup(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
}
