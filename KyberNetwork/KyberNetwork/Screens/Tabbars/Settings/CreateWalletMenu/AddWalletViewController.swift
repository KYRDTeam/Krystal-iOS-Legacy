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
  case close
}

protocol AddWalletViewControllerDelegate: class {
  func addWalletViewController(_ controller: AddWalletViewController, run event: AddWalletViewControllerEvent)
}

class AddWalletViewController: KNBaseViewController {
  weak var delegate: AddWalletViewControllerDelegate?
  var isCloseByGesture: Bool = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    isCloseByGesture = true
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isCloseByGesture {
      self.delegate?.addWalletViewController(self, run: .close)
    }
  }

  @IBAction func createWalletButtonTapped(_ sender: Any) {
    isCloseByGesture = false
    self.delegate?.addWalletViewController(self, run: .createWallet)
  }

  @IBAction func importWalletButtonTapped(_ sender: Any) {
    isCloseByGesture = false
    self.delegate?.addWalletViewController(self, run: .importWallet)
  }
  
  @IBAction func onCloseButtonTapped(_ sender: Any) {
    isCloseByGesture = false
    self.navigationController?.popViewController(animated: false, completion: {
      self.delegate?.addWalletViewController(self, run: .close)
    })
  }
}
