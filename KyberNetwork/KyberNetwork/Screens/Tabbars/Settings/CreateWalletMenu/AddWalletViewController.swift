//
//  AddWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 31/08/2022.
//

import UIKit


enum AddWalletViewControllerEvent {
  case createWallet
  case importWallet
  case importWatchWallet
  case close
}

protocol AddWalletViewControllerDelegate: class {
  func addWalletViewController(_ controller: AddWalletViewController, run event: AddWalletViewControllerEvent)
}


class AddWalletViewController: KNBaseViewController {
  weak var delegate: AddWalletViewControllerDelegate?
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func createWalletButtonTapped(_ sender: Any) {
    self.delegate?.addWalletViewController(self, run: .createWallet)
  }

  @IBAction func importWalletButtonTapped(_ sender: Any) {
    self.delegate?.addWalletViewController(self, run: .importWallet)
  }
  
  @IBAction func onCloseButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true, completion: {
      self.delegate?.addWalletViewController(self, run: .close)
    })
  }
}
