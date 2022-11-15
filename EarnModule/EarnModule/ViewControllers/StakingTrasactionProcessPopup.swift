//
//  StakingTrasactionProcessPopup.swift
//  KyberNetwork
//
//  Created by Tạ Minh Quân on 02/11/2022.
//

import UIKit
import AppState
import Utilities
import DesignSystem
import TransactionModule
import Dependencies

class StakingTrasactionProcessPopup: KNBaseViewController {
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    
    @IBOutlet weak var txHashLabel: UILabel!
    @IBOutlet weak var loadingIndicatorView: CountdownTimer!
    @IBOutlet weak var statusContainerView: UIView!
    @IBOutlet weak var transactionStateIcon: UIImageView!
    
    @IBOutlet weak var sourceTokenInfoContainerView: UIView!
    @IBOutlet weak var destTokenInfoContainerView: UIView!
    @IBOutlet weak var sourceTokenIcon: UIImageView!
    @IBOutlet weak var sourceTokenAmountLabel: UILabel!
    @IBOutlet weak var destTokenIcon: UIImageView!
    @IBOutlet weak var destTokenAmountLabel: UILabel!
    @IBOutlet weak var processStatusLabel: UILabel!
    
    var tx: PendingStakingTxInfo!
    
    var onSelectViewPool: (() -> ())?
    
    var state: TxStatus = .processing {
        didSet {
            self.updateUIForStateChange(self.state)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLoadingView()
        observeEvents()
        state = .processing
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
        guard hash == tx.hash else {
            return
        }
        
        updateView(status: status)
    }
    
    func updateUIForStateChange(_ state: TxStatus) {
        switch state {
        case .processing:
            self.loadingIndicatorView.isHidden = false
            self.transactionStateIcon.isHidden = true
            self.statusContainerView.bringSubviewToFront(self.loadingIndicatorView)
            self.loadingIndicatorView.start(beginingValue: 1)
            let buttonTitle = "Open \(AppState.shared.currentChain.customRPC().webScanName)"
            self.secondButton.setTitle(buttonTitle, for: .normal)
            self.sourceTokenInfoContainerView.rounded(color: AppTheme.current.primaryColor, width: 1, radius: 16)
            self.destTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
            self.processStatusLabel.text = Strings.stakingInProgress
        case .success:
            self.loadingIndicatorView.isHidden = true
            self.transactionStateIcon.isHidden = false
            self.statusContainerView.bringSubviewToFront(self.transactionStateIcon)
            self.transactionStateIcon.image = UIImage(named: "tx_status_success")
            self.secondButton.setTitle("", for: .normal)
            let buttonTitle = Strings.viewMyPool
            self.secondButton.setTitle(buttonTitle, for: .normal)
            self.destTokenInfoContainerView.rounded(color: AppTheme.current.primaryColor, width: 1, radius: 16)
            self.sourceTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
            self.processStatusLabel.text = Strings.success
        case .failure:
            self.loadingIndicatorView.isHidden = true
            self.transactionStateIcon.isHidden = false
            self.statusContainerView.bringSubviewToFront(self.transactionStateIcon)
            self.transactionStateIcon.image = UIImage(named: "tx_status_fail")
            let buttonTitle = Strings.support
            self.secondButton.setTitle(buttonTitle, for: .normal)
            self.destTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
            self.sourceTokenInfoContainerView.rounded(color: UIColor.clear, width: 0, radius: 16)
            self.processStatusLabel.text = Strings.txFailed
        }
    }
    
    func setupUI() {
        self.sourceTokenIcon.loadImage(tx.sourceIcon)
        self.destTokenIcon.loadImage(tx.platform.logo)
        self.txHashLabel.text = self.tx.hash
        let descriptions = self.tx.description.split(separator: "→").map { String($0) }
        self.sourceTokenAmountLabel.text = descriptions.first ?? ""
        self.destTokenAmountLabel.text = tx.platform.name.uppercased()
        
    }
    
    fileprivate func setupLoadingView() {
        self.loadingIndicatorView.lineWidth = 2
        self.loadingIndicatorView.lineColor = UIColor(named: "buttonBackgroundColor")!
        self.loadingIndicatorView.labelTextColor = UIColor(named: "buttonBackgroundColor")!
        self.loadingIndicatorView.trailLineColor = UIColor(named: "buttonBackgroundColor")!.withAlphaComponent(0.2)
        self.loadingIndicatorView.isLoadingIndicator = true
        self.loadingIndicatorView.isLabelHidden = true
    }
    
    func updateView(status: InternalTransactionState) {
        switch status {
        case .pending:
            self.state = .processing
        case .error, .drop:
            state = .failure
        case .done:
            state = .success
        default:
            state = .processing
        }
    }
    
    @IBAction func secondButtonTapped(_ sender: UIButton) {
        switch state {
        case .processing:
            self.txHashButtonTapped(sender)
        case .success:
            dismiss(animated: true) { [weak self] in
                self?.onSelectViewPool?()
            }
        case .failure:
            dismiss(animated: true) {
                AppDependencies.router.openSupportURL()
            }
        }
    }
    
    @IBAction func firstButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func txHashButtonTapped(_ sender: UIButton) {
        let urlString = AppState.shared.currentChain.customRPC().etherScanEndpoint + "tx/\(self.tx.hash)"
        dismiss(animated: true) {
            AppDependencies.router.openExternalURL(url: urlString)
        }
    }
}
