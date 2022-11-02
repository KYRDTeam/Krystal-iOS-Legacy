//
//  RevokeTxStatusPopup.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/11/2022.
//

import UIKit
import DesignSystem
import BaseWallet

class RevokeTxStatusPopup: UIViewController {
    @IBOutlet weak var txHashLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loadingView: CountdownTimer!
    @IBOutlet weak var statusIconImageView: UIImageView!
    @IBOutlet weak var primaryButton: UIButton!
    
    var onSelectOpenExplorer: (() -> Void)?
    var onSelectContactSupport: (() -> Void)?
    
    var txHash: String!
    var chain: ChainType!
    var status: Status = .broadcasting
    
    enum Status {
        case broadcasting
        case success
        case failed
    }
    
    var explorerTitle: String {
        return String(format: Strings.openX, chain.customRPC().webScanName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadUI()
        observeTxStatus()
        txHashLabel.text = txHash
        setupLoadingView()
        loadingView.start(beginingValue: 1)
    }
    
    func setupLoadingView() {
        loadingView.lineWidth = 2
        loadingView.lineColor = AppTheme.current.primaryColor
        loadingView.labelTextColor = AppTheme.current.primaryColor
        loadingView.trailLineColor = AppTheme.current.primaryColor.withAlphaComponent(0.2)
        loadingView.isLoadingIndicator = true
        loadingView.isLabelHidden = true
    }
    
    func reloadUI() {
        switch status {
        case .broadcasting:
            loadingView.isHidden = false
            statusIconImageView.isHidden = true
            titleLabel.text = Strings.broadcastingTransaction
            primaryButton.setTitle(explorerTitle, for: .normal)
        case .success:
            loadingView.isHidden = true
            statusIconImageView.isHidden = false
            titleLabel.text = Strings.success
            statusIconImageView.image = Images.txStatusSuccess
            primaryButton.setTitle(explorerTitle, for: .normal)
        case .failed:
            loadingView.isHidden = true
            statusIconImageView.isHidden = false
            titleLabel.text = Strings.transactionFailed
            statusIconImageView.image = Images.txStatusFailed
            primaryButton.setTitle(Strings.support, for: .normal)
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func primaryButtonTapped(_ sender: Any) {
        switch status {
        case .failed:
            dismiss(animated: true) { [weak self] in
                self?.onSelectContactSupport?()
            }
        default:
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.onSelectOpenExplorer?()
            }
        }
    }
    
    @IBAction func explorerTapped(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onSelectOpenExplorer?()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(kTransactionDidUpdateNotificationKey),
            object: nil
        )
    }
    
    func observeTxStatus() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.transactionStateDidUpdate(_:)),
            name: Notification.Name(kTransactionDidUpdateNotificationKey),
            object: nil
        )
        
    }
    
    @objc func transactionStateDidUpdate(_ sender: Notification) {
        guard let transaction = sender.object as? InternalHistoryTransaction else { return }
        if self.txHash == transaction.hash {
            switch transaction.state {
            case .drop, .error:
                status = .failed
            case .done:
                status = .success
            default:
                return
            }
            reloadUI()
        }
    }
    
}
