//
//  BackupRemindViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/03/2023.
//

import UIKit
import DesignSystem

class BackupRemindViewController: UIViewController {
    
    @IBOutlet weak var dontRemindCheckBox: CheckBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func dontRemindCheckBoxTapped(_ sender: Any) {
        dontRemindCheckBox.isChecked.toggle()
    }

}
