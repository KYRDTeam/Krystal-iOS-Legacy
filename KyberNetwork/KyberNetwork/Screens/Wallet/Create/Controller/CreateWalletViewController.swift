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
  
  weak var delegate: CreateWalletViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateWalletName()
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
    
    let wallets = WalletManager.shared.getAllWallets()
    let name = self.walletNameTextField.text ?? "Wallet \(wallets.count + 1)"
    self.delegate?.createWalletViewController(self, run: .next(name: name))
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
