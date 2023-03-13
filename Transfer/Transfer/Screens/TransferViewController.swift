//
//  TransferViewController.swift
//  Transfer
//
//  Created by Tung Nguyen on 24/02/2023.
//

import UIKit
import TransactionModule

class TransferViewController: UIViewController {
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var addresssInfoLabel: UILabel!
    
    var viewModel: TransferViewModelProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func settingTapped(_ sender: Any) {
        TransactionSettingPopup.show(on: self, chain: .eth) { settingObject in
            
        }
    }
    
    @IBAction func maxTapped(_ sender: Any) {
        
    }
    
    func onAmountChanged(value: String) {
        
    }
}

extension TransferViewController: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        onAmountChanged(value: textField.text ?? "")
        return true
    }
    
}
