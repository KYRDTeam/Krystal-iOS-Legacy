//
//  BackupRemindViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/03/2023.
//

import UIKit
import DesignSystem
import Dependencies

class BackupRemindViewController: UIViewController {
    
    @IBOutlet weak var dontRemindCheckBox: CheckBox!
    
    var dontRemind: Bool = false
    var walletID: String = ""
    let manager = WalletExtraDataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manager.updateLastBackupRemindTime(walletID: walletID)
    }

    @IBAction func dontRemindCheckBoxTapped(_ sender: Any) {
        dontRemindCheckBox.isChecked.toggle()
        dontRemind = dontRemindCheckBox.isChecked
    }
    
    @IBAction func notNowTapped(_ sender: Any) {
        if dontRemind {
            self.manager.stopRemindBackup(walletID: self.walletID)
        }
        dismiss(animated: true)
    }
    
    @IBAction func backupTapped(_ sender: Any) {
        dismiss(animated: true) {
            AppDependencies.router.openBackupWallet(walletID: self.walletID)
        }
    }

}
