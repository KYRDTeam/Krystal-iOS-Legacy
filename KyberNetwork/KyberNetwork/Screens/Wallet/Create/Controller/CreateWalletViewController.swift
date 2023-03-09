//
//  CreateWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 16/08/2022.
//

import UIKit
import KrystalWallets

enum CreateWalletViewControllerEvent {
  case back
  case next(name: String)
  case openQR
  case sendRefCode(code: String)
}

protocol CreateWalletViewControllerDelegate: class {
  func createWalletViewController(_ controller: CreateWalletViewController, run event: CreateWalletViewControllerEvent)
}

class CreateWalletViewController: KNBaseViewController {
  @IBOutlet weak var refCodeTextField: UITextField!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var createButton: UIButton!
  @IBOutlet weak var createButtonTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var referralTitleLabel: UILabel!
  @IBOutlet weak var referralView: UIView!
    
  weak var delegate: CreateWalletViewControllerDelegate?
  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateWalletName()
    if FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.refcode) {
        createButtonTopConstraint.constant = 60
        referralTitleLabel.isHidden = true
        referralView.isHidden = true
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateWalletName()
    self.createButton.isUserInteractionEnabled = true
  }
  
  func updateWalletName() {
    let wallets = WalletManager.shared.getAllWallets()
    self.walletNameTextField.text = "Wallet \(wallets.count + 1)"
  }
  
  func containerViewDidUpdateRefCode(_ refCode: String) {
    self.refCodeTextField.text = refCode
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.delegate?.createWalletViewController(self, run: .back)
  }
  
  @IBAction func onCreateButtonTapped(_ sender: Any) {
    self.createButton.isUserInteractionEnabled = false
    if let text = self.refCodeTextField.text, !text.isEmpty {
      self.delegate?.createWalletViewController(self, run: .sendRefCode(code: text.uppercased()))
    }
    self.navigationController?.displayLoading(text: Strings.creating, animated: true)
    do {
        let wallets = WalletManager.shared.getAllWallets()
        let wallet = try WalletManager.shared.createWallet(name: "Wallet \(wallets.count + 1)")
        DispatchQueue.main.async {
            self.navigationController?.hideLoading()
            let viewModel = FinishImportViewModel(wallet: wallet)
            let finishVC = FinishImportViewController(viewModel: viewModel)
            self.navigationController?.show(finishVC, sender: nil)
            MixPanelManager.track("create_wallet", properties: ["screenid": "create_wallet"])
        }
    } catch {
        return
    }
  }
  
  @IBAction func pasteButtonTapped(_ sender: Any) {
    if let string = UIPasteboard.general.string {
      self.refCodeTextField.text = string
    }
  }
  
  @IBAction func scanButtonTapped(_ sender: Any) {
    self.delegate?.createWalletViewController(self, run: .openQR)
  }
}

extension CreateWalletViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let textFieldText = textField.text else {
      return false
    }
    return textFieldText.count < 32
  }
}
