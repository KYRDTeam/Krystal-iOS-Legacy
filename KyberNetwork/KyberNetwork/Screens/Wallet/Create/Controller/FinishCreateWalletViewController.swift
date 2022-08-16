//
//  FinishCreateWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 16/08/2022.
//

import UIKit

class FinishCreateWalletViewController: KNBaseViewController {
  @IBOutlet weak var dashView: UIView!
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }
  
  func setupUI() {
    self.dashView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func onContinueButtonTapped(_ sender: Any) {
    
  }
  
  
  @IBAction func onBackupWalletButtonTapped(_ sender: Any) {
    
  }

}
