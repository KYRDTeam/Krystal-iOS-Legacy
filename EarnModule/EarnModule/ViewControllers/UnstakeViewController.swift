//
//  UnstakeViewController.swift
//  EarnModule
//
//  Created by Com1 on 08/11/2022.
//

import UIKit
import DesignSystem

class UnstakeViewController: InAppBrowsingViewController {
    @IBOutlet weak var unstakePlatformLabel: UILabel!
    @IBOutlet weak var availableUnstakeValue: UILabel!
    @IBOutlet weak var unstakeButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var tokenIcon: UIImageView!
    @IBOutlet weak var amountViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var amountView: UIView!
    
    @IBOutlet weak var receiveInfoView: TxInfoView!
    @IBOutlet weak var rateView: TxInfoView!
    @IBOutlet weak var networkFeeView: TxInfoView!
    @IBOutlet weak var receiveTimeView: TxInfoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        self.amountTextField.setPlaceholder(text: Strings.searchToken, color: AppTheme.current.secondaryTextColor)
        receiveInfoView.setInfo(title: "You will receive", value: "0 stMATIC")
        rateView.setInfo(title: "Rate", value: "0 stMATIC", shouldShowIcon: true)
        networkFeeView.setInfo(title: "Network Fee", value: "0 stMATIC")
        receiveTimeView.setInfo(title: "You will receive your MATIC in 2-3 days", value: "")
    }
    
    @IBAction func settingButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func maxButtonTapped(_ sender: Any) {
        hideError()
    }
    
    @IBAction func unstakeButtonTapped(_ sender: Any) {
        showError()
    }
    
    func showError() {
        amountView.shakeViewError()
        amountViewBottomConstraint.constant = 54
        receiveTimeView.isHidden = true
    }
    
    func hideError() {
        amountView.removeError()
        amountViewBottomConstraint.constant = 24
        receiveTimeView.isHidden = false
    }
}
