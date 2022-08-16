//
//  CreateWalletViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 16/08/2022.
//

import UIKit

class CreateWalletViewController: KNBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func onCreateButtonTapped(_ sender: Any) {
    let finishVC = FinishCreateWalletViewController()
    self.show(finishVC, sender: nil)
  }
}
