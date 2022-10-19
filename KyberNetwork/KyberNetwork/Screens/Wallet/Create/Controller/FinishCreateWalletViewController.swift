//
//  FinishCreateWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 16/08/2022.
//

import UIKit
import KrystalWallets

enum FinishCreateWalletViewControllerEvent {
  case continueUseApp
  case backup
}

protocol FinishCreateWalletViewControllerDelegate: class {
  func finishCreateWalletViewController(_ controller: FinishCreateWalletViewController, run event: FinishCreateWalletViewControllerEvent)
}

class FinishCreateWalletViewModel {
  let wallet: KWallet
  init(wallet: KWallet) {
    self.wallet = wallet
  }
  
  func getSolanaAddress() -> String {
    return WalletManager.shared.address(walletID: wallet.id, addressType: .solana)?.addressString ?? ""
  }
  
  func getEVMAddress() -> String {
    return WalletManager.shared.address(walletID: wallet.id, addressType: .evm)?.addressString ?? ""
  }
}

class FinishCreateWalletViewController: KNBaseViewController {
  @IBOutlet weak var dashView: UIView!
  @IBOutlet weak var evmAddressLabel: UILabel!
  @IBOutlet weak var solanaAddressLabel: UILabel!
  weak var delegate: FinishCreateWalletViewControllerDelegate?
  let viewModel: FinishCreateWalletViewModel
  
  init(viewModel: FinishCreateWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: FinishCreateWalletViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    MixPanelManager.track("create_wallet_done_open", properties: ["screenid": "create_wallet_don"])
  }

  func setupUI() {
    self.dashView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
    self.evmAddressLabel.text = self.viewModel.getEVMAddress()
    self.solanaAddressLabel.text = self.viewModel.getSolanaAddress()
  }

  @IBAction func onContinueButtonTapped(_ sender: Any) {
    self.delegate?.finishCreateWalletViewController(self, run: .continueUseApp)
    MixPanelManager.track("create_done_continue", properties: ["screenid": "create_wallet_done"])
  }

  @IBAction func onBackupWalletButtonTapped(_ sender: Any) {
    self.delegate?.finishCreateWalletViewController(self, run: .backup)
    MixPanelManager.track("create_done_back_up_wallet", properties: ["screenid": "create_wallet_done"])
  }
}
