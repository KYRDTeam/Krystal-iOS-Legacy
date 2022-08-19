//
//  BackupSuccessViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 19/08/2022.
//

import UIKit

protocol BackupSuccessViewControllerDelegate: class {
  func didFinishBackup(_ controller: BackupSuccessViewController)
}

class BackupSuccessViewController: KNBaseViewController {
  weak var delegate: BackupSuccessViewControllerDelegate?
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func continueButtonTapped(_ sender: Any) {
    self.delegate?.didFinishBackup(self)
  }
}
