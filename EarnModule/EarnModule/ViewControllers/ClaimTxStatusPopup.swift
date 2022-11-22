//
//  ClaimTxStatusPopup.swift
//  EarnModule
//
//  Created by Tung Nguyen on 16/11/2022.
//

import UIKit
import DesignSystem
import Dependencies
import TransactionModule

class ClaimTxStatusPopup: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusIconImageView: UIImageView!
    @IBOutlet weak var tokenIconImageView: UIImageView!
    @IBOutlet weak var tokenAmountLabel: UILabel!
    @IBOutlet weak var hashLabel: UILabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!
    @IBOutlet weak var loadingView: CountdownTimer!
    
    var viewModel: ClaimTxStatusViewModel!
    var onOpenPortfolio: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        bindViewModel()
        observeEvents()
    }
    
    func setupViews() {
        titleLabel.text = viewModel.statusString
        tokenIconImageView.loadImage(viewModel.pendingTx.pendingUnstake.logo)
        tokenAmountLabel.text = viewModel.tokenAmountString
        hashLabel.text = viewModel.hashString
        setupLoadingView()
    }
    
    func setupLoadingView() {
        loadingView.lineWidth = 2
        loadingView.lineColor = AppTheme.current.primaryColor
        loadingView.labelTextColor = AppTheme.current.primaryColor
        loadingView.trailLineColor = AppTheme.current.primaryColor.withAlphaComponent(0.2)
        loadingView.isLoadingIndicator = true
        loadingView.isLabelHidden = true
        loadingView.start(beginingValue: 1)
    }
    
    func bindViewModel() {
        viewModel.onStatusUpdated = { [weak self] in
            self?.titleLabel.text = self?.viewModel.statusString
            self?.loadingView.isHidden = self?.viewModel.isInProgress == false
            self?.statusIconImageView.isHidden = self?.viewModel.isInProgress == true
            self?.primaryButton.setTitle(self?.viewModel.primaryButtonTitle, for: .normal)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .kTxStatusUpdated, object: nil)
    }
    
    func observeEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.txStatusUpdated(_:)),
            name: .kTxStatusUpdated,
            object: nil
        )
    }
    
    @objc func txStatusUpdated(_ notification: Notification) {
        guard let hash = notification.userInfo?["hash"] as? String, let status = notification.userInfo?["status"] as? InternalTransactionState else {
            return
        }
        guard hash == viewModel.pendingTx.hash else {
            return
        }
        
        viewModel.updateStatus(status: getTxStatus(status: status))
    }
    
    func getTxStatus(status: InternalTransactionState) -> TxStatus {
        switch status {
        case .pending:
            return .processing
        case .error, .drop:
            return .failure
        case .done:
            return .success
        default:
            return .processing
        }
    }
    
    @IBAction func secondaryButtonTapped(sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func primaryButtonTapped(sender: UIButton) {
        switch viewModel.status {
        case .processing:
            dismiss(animated: true) {
                AppDependencies.router.openTxHash(txHash: self.viewModel.hashString, chainID: self.viewModel.pendingTx.pendingUnstake.chainID)
            }
        case .success:
            dismiss(animated: true) { [weak self] in
                self?.onOpenPortfolio?()
            }
        case .failure:
            dismiss(animated: true) {
                AppDependencies.router.openSupportURL()
            }
        }
    }
    

}
