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
    @IBOutlet weak var reasonStackView: UIStackView!
    
    var dontRemind: Bool = false
    var walletID: String = ""
    let manager = WalletExtraDataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        manager.updateLastBackupRemindTime(walletID: walletID)
        reasonStackView.isUserInteractionEnabled = true
        reasonStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onReasonTapped)))
    }

    @objc func onReasonTapped() {
        let vc = TipsViewController.instantiateFromNib()
        vc.dataSource = [TipModel(title: Strings.backupReasonTitle, detail: Strings.backupReasonContent)]
        vc.title = Strings.backupWallet
        navigationController?.pushViewController(vc, animated: true)
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

    @IBAction func reasonTitleTapped(_ sender: Any) {
        onReasonTapped()
    }
}
